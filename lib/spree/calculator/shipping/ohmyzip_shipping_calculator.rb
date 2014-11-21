class Spree::Calculator::Shipping::Ohmyzip < Spree::ShippingCalculator
  preference :local_shipping_charge, :decimal, default: 0
  preference :international_shipping_charge, :decimal, default: 7.50
  preference :default_weight, :decimal, default: 1
  preference :promotional_shipping_discount, :boolean, default: true

  def self.description
    "Ohmyzip Shipping Calculator"
  end

  def self.register
    super
  end


  def local_shipping_amount(order)
    BigDecimal.new(order.check_for_gap_banana_products? ? 7 : 0)
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
    return 0 if (package.order.item_count > 1 and preferences[:promotional_shipping_discount])
    content_items = package.contents
    total_weight = total_weight(content_items)
    base_price = preferred_international_shipping_charge + (order_contains_ilbantongwan?(package) ? 1.00 : 0)

    shipping_cost = total_weight * 2 + base_price
    shipping_cost + local_shipping_amount(package.order)
  end

  # computes in USD – does NOT include local shipping upgrade
  def compute_amount(order)
    return 0 if (order.item_count > 1 and preferences[:promotional_shipping_discount])
    content_items = order.line_items
    total_weight = total_weight(content_items)
    base_price = preferred_international_shipping_charge + (order_contains_ilbantongwan?(order) ? 1.00 : 0)

    shipping_cost = total_weight * 2 + base_price
    shipping_cost
  end

  def relaxation_shipping_amount(order)
    content_items = order.line_items
    total_weight = total_weight(content_items)
    base_price = preferred_international_shipping_charge + (order_contains_ilbantongwan?(order) ? 1.00 : 0)

    shipping_cost = total_weight * 2 + base_price
    shipping_cost
  end

  def compute_product_amount(product)
    weight = 0
    weight = product.master.weight > 0.0 ? product.master.weight / 100 : preferred_default_weight
    weight.ceil
    base_price = preferred_international_shipping_charge
    shipping_cost = weight * 2 + base_price
    shipping_cost
  end

  def total_weight(contents)
    weight = 0
    contents.each do |item|
      weight += item.quantity * (item.variant.weight > 0.0 ? item.variant.weight / 100 : preferred_default_weight)
    end
    weight.ceil
  end

  private
  def order_contains_ilbantongwan?(contents)
    return false
    ### TODO: set up the below logic if we're selling non-fashion
    #contents.each do |item|
    ###check each item's category to see if it's not 목록통관
    #end
  end
end

