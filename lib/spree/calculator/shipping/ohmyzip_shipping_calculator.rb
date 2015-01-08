class Spree::Calculator::Shipping::Ohmyzip < Spree::ShippingCalculator
  preference :local_shipping_charge, :decimal, default: 0
  preference :default_weight, :decimal, default: 1
  preference :promotional_shipping_discount, :boolean, default: true

  def self.description
    "Ohmyzip Shipping Calculator"
  end

  def self.register
    super
  end

  # the82 shipping charge in USD
  def international_shipping_charge weight
    if weight > 7
      (18.4 + (weight - 7) * 1.72).round(2)
    else
      @shipping_rate ||= [9.0, 9.0, 11.2, 13.0, 14.8, 16.9, 17.8, 18.4]
      @shipping_rate[weight]
    end
  end

  def local_shipping_amount(order)
    order.check_for_gap_banana_products? ? 7 : 0
  end

  def display_string_local_shipping_amount amount = 0
    presentation_currency = Spree::Config[:presentation_currency] if Spree::Config[:presentation_currency] != nil
    @rate = if @rate then @rate else Spree::CurrencyRate.find_by(target_currency: presentation_currency) end
    @rate.convert_to_won(amount).amount.ceil.to_s
  end

  # should display in KRW
  def display_local_shipping_amount
    presentation_currency = Spree::Config[:presentation_currency] if Spree::Config[:presentation_currency] != nil
    @rate = if @rate then @rate else Spree::CurrencyRate.find_by(target_currency: presentation_currency) end
    display_amount = Spree::Money.new(@rate.convert_to_won(amount).amount, { currency: presentation_currency })
    preferred_local_shipping_charge == 0 ? "기본" : "+ <strong>#{display_amount}</strong>".html_safe
  end

  def available?(package)
    true
  end

  # computes in USD
  def compute_package(package)
    if (package.order.item_count > 1 and preferences[:promotional_shipping_discount]) and (package.order.completed_at.nil? or package.order.completed_at >= Date.parse('2014-11-23'))
      return local_shipping_amount(package.order)
    end
    content_items = package.contents
    total_weight = total_weight(content_items)
    shipping_cost = international_shipping_charge(total_weight) + local_shipping_amount(package.order)
    shipping_cost
  end

  # computes in USD – does NOT include local shipping upgrade
  def compute_amount(order)
    if (order.item_count > 1 and preferences[:promotional_shipping_discount]) and (order.completed_at.nil? or order.completed_at >= Date.parse('2014-11-23'))
      return local_shipping_amount(order)
    end
    content_items = order.line_items
    total_weight = total_weight(content_items)
    shipping_cost = international_shipping_charge(total_weight) + local_shipping_amount(order)
    shipping_cost
  end

  def relaxation_shipping_amount(order)
    content_items = order.line_items
    total_weight = total_weight(content_items)
    international_shipping_charge(total_weight)
  end

  def compute_product_amount(product)
    if product.variants.present?
      weight = product.variants.maximum(:weight)
    else
      weight = product.master.weight
    end
    weight = weight > 0.0 ? weight / 100 : preferred_default_weight
    weight = weight.ceil

    international_shipping_charge(weight)
  end

  def total_weight(contents)
    weight = 0
    contents.each do |item|
      weight += item.quantity * (item.variant.weight > 0.0 ? item.variant.weight / 100 : preferred_default_weight)
    end
    weight.ceil
  end

end

