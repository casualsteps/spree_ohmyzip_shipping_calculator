class Spree::Calculator::Shipping::Ohmyzip < Spree::ShippingCalculator
  preference :snapshop_shipping_markup, :decimal, default: 1 # dollars
  preference :default_weight, :decimal, default: 1
  preference :promotional_shipping_discount, :boolean, default: false

  def self.description
    "Ohmyzip Shipping Calculator"
  end

  def self.register
    super
  end

  # the82 shipping charge in USD
  def international_shipping_charge(weight)
    shipping_charge = (9 + 2 * weight).round(2)
    shipping_charge + preferred_snapshop_shipping_markup
  end

  def local_shipping_amount(product_or_order)
    # get an array of products to iterate on
    products = []
    case product_or_order
      when Spree::Product
        products.push product_or_order
      when Spree::Order
        product_or_order.line_items.each {|li|
          for i in 0..li.quantity-1
            products.push li.product
          end
        }
    end

    return nil if products.empty?

    products_by_merchant = products.group_by { |p| p.merchant }
    local_shipping_total = 0
    products_by_merchant.map do |merchant, products|
      merchant_total = products.sum(&:price).to_f
      case merchant
        when "gap", "bananarepublic"
          local_shipping_total += 7
        when "footlocker"
          local_shipping_total += 7.99 + ((products.count-1) * 1.99)
        when "ssense"
          # ssense local shipping is free for now. 
          # Use the code below if they change it later:
          #
          #local_shipping_total += 12 if merchant_total <= 200
      end
    end

    local_shipping_total
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
    international_shipping_charge(total_weight) + local_shipping_amount(package.order)
  end

  # computes in USD
  def compute_amount(order)
    if (order.item_count > 1 and preferences[:promotional_shipping_discount]) and (order.completed_at.nil? or order.completed_at >= Date.parse('2014-11-23'))
      return local_shipping_amount(order)
    end
    content_items = order.line_items
    total_weight = total_weight(content_items)
    international_shipping_charge(total_weight) + local_shipping_amount(order)
  end

  def relaxation_shipping_amount(order)
    content_items = order.line_items
    total_weight = total_weight(content_items)
    international_shipping_charge(total_weight)
  end

  def _compute_product_weight(product)
    if product.variants.present?
      weight = product.variants.maximum(:weight)
    else
      weight = product.master.weight
    end
    weight = weight > 0.0 ? weight / 100 : preferred_default_weight
    weight = weight.ceil
  end

  def compute_product_amount(product)
    weight = _compute_product_weight(product)
    international_shipping_charge(weight) + local_shipping_amount(product)
  end
  
  def show_shipping_charge(location, currency, product)
    if (location == "local")
      shipping_cost = local_shipping_amount(product)
    elsif (location == "international")
      weight = _compute_product_weight(product)
      shipping_cost = international_shipping_charge(weight)
    end
    if (currency == "KRW")
      rate = Spree::CurrencyRate.find_by(target_currency: currency)
      return Spree::Money.new(rate.convert_to_won(shipping_cost).amount, { currency: currency }).to_html
    elsif (currency == "USD")
      return Spree::Money.new(shipping_cost, { currency: currency }).to_html
    end
  end

  def total_weight(contents)
    weight = 0
    contents.each do |item|
      weight += item.quantity * (item.variant.weight > 0.0 ? item.variant.weight / 100 : preferred_default_weight)
    end
    weight.ceil
  end
end
