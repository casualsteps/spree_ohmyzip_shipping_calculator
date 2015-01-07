class Spree::Calculator::Shipping::Ohmyzip < Spree::ShippingCalculator
  preference :local_shipping_charge, :decimal, default: 0
  preference :default_weight, :decimal, default: 1
  preference :promotional_shipping_discount, :boolean, default: true

  # the82 shipping charge
  @@international_shipping_charge = [9.0, 11.2, 13.0, 14.8, 16.9, 17.8, 18.4]
  93.times do
    price = @@international_shipping_charge.last + 1.72
    @@international_shipping_charge.push(price.round(2))
  end

  def self.description
    "Ohmyzip Shipping Calculator"
  end

  def self.register
    super
  end


  def local_shipping_amount
    preferred_local_shipping_charge
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
    return 0 if (package.order.item_count > 1 and preferences[:promotional_shipping_discount]) and (package.order.completed_at.nil? or package.order.completed_at >= Date.parse('2014-11-23'))
    content_items = package.contents
    total_weight = total_weight(content_items)
    shipping_cost = @@international_shipping_charge[total_weight - 1]
    shipping_cost + preferred_local_shipping_charge
  end

  # computes in USD – does NOT include local shipping upgrade
  def compute_amount(order)
    return 0 if (order.item_count > 1 and preferences[:promotional_shipping_discount]) and (order.completed_at.nil? or order.completed_at >= Date.parse('2014-11-23'))
    content_items = order.line_items
    total_weight = total_weight(content_items)
    @@international_shipping_charge[total_weight - 1]
  end

  def relaxation_shipping_amount(order)
    content_items = order.line_items
    total_weight = total_weight(content_items)
    @@international_shipping_charge[total_weight - 1]
  end

  def compute_product_amount(product)
    if product.variants.present?
      weight = product.variants.maximum(:weight)
    else
      weight = product.master.weight
    end
    weight = weight > 0.0 ? weight / 100 : preferred_default_weight
    weight = weight.ceil

    @@international_shipping_charge[weight - 1]
  end

  def total_weight(contents)
    weight = 0
    contents.each do |item|
      weight += item.quantity * (item.variant.weight > 0.0 ? item.variant.weight / 100 : preferred_default_weight)
    end
    weight.ceil
  end

end

