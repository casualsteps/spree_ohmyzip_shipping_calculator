class Spree::Calculator::Shipping::Ohmyzip < Spree::ShippingCalculator
  preference :local_shipping_charge, :integer, default: 0
  preference :default_weight, :decimal, default: 1

  def self.description
    "Ohmyzip Shipping Calculator"
  end

  def self.register
    super
  end

  def local_shipping_amount
    preferred_local_shipping_charge
  end

  def display_local_shipping_amount
    display_amount = Spree::Money.new(preferred_local_shipping_charge, { currency: "KRW" })
    preferred_local_shipping_charge == 0 ? "기본" : "+ <strong>#{display_amount}</strong>".html_safe
  end

  def available?(package)
    true
  end

  def compute_package(package)
    content_items = package.contents
    total_weight = total_weight(content_items)
    base_price = order_contains_ilbantongwan?(package) ? 7.50 : 6.50

    shipping_cost = total_weight*2 + base_price
    total = Spree::CurrencyRate.find_by(:base_currency => 'USD').convert_to_won(shipping_cost).fractional
    total + preferred_local_shipping_charge
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

  def express_shipping_charge(order)
    preferred_express_shipping ? "3,000" : "0"
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

