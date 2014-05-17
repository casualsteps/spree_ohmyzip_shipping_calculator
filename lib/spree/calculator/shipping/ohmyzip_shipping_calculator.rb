class Spree::Calculator::Shipping::Ohmyzip < Spree::ShippingCalculator
  preference :default_weight, :decimal, default: 1

  def self.description
    "Ohmyzip Shipping Calculator"
  end

  def self.register
    super
  end

  def available?(package)
    true
  end

  def compute_package(package)
    content_items = package.contents
    total_weight = total_weight(content_items)
    base_price = order_contains_ilbantongwan?(package) ? 7.50 : 6.50

    shipping_cost = total_weight*2 + base_price
    Spree::CurrencyRate.find_by(:base_currency => 'USD').convert_to_won(shipping_cost).fractional
  end

  def compute_amount(order)
    content_items = order.line_items
    total_weight = total_weight(content_items)
    base_price = order_contains_ilbantongwan?(order) ? 7.50 : 6.50

    shipping_cost = total_weight*2 + base_price
    Spree::CurrencyRate.find_by(:base_currency => 'USD').convert_to_won(shipping_cost).fractional
  end

  def display_amount(order)
    total = compute_amount(order)
    Spree::Money.new(total, { currency: "KRW" })
  end

  def total_weight(contents)
    weight = 0
    contents.each do |item|          
      weight += item.quantity * (item.variant.weight > 0.0 ? item.variant.weight : preferred_default_weight)
    end
    weight
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

