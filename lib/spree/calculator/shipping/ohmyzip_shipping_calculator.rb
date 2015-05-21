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
    products = []
    case product_or_order
    when Spree::Product
      products.push product_or_order
    when Spree::Order
      product_or_order.line_items.includes(variant: :product).each do |li|
        li.quantity.times { products.push li.product }
      end
    end

    return 0 if products.empty?

    products.group_by(&:merchant).inject(0) do |total, (merchant, products)|
      #merchant_total = products.sum(&:price).to_f
      case merchant
      when "gap", "bananarepublic"
        total += 7
      when "footlocker"
        total += 7.99 + ((products.count-1) * 1.99)
      when "ssense"
        # ssense local shipping is free for now.
        # Use the code below if they change it later:
        #
        # total += 12 if merchant_total <= 200
        total
      else
        total
      end
    end
  end

  def available?(package)
    true
  end

  # computes in USD
  def _compute(order, contents)
    if (order.item_count > 1 && preferences[:promotional_shipping_discount]) && (order.completed_at.nil? || order.completed_at >= Date.parse('2014-11-23'))
      return local_shipping_amount(order)
    end
    international_shipping_charge_for_items(contents.includes(:variant)) + local_shipping_amount(order)
  end

  # computes in USD
  def compute_package(package)
    _compute(package.order, package.contents)
  end

  # computes in USD
  def compute_amount(order)
    _compute(order, order.line_items)
  end

  def international_shipping_charge_for_items(content_items)
    total_weight = total_weight(content_items)
    international_shipping_charge(total_weight)
  end
  # TODO: remove after it's removed from master
  def relaxation_shipping_amount(order)
    international_shipping_charge_for_items(order.line_items)
  end

  def compute_product_amount(product)
    weight = compute_product_weight(product)
    international_shipping_charge(weight) + local_shipping_amount(product)
  end
  
  def show_shipping_charge(location, currency, product)
    case location
    when "local"
      shipping_cost = local_shipping_amount(product)
    when "international"
      weight = compute_product_weight(product)
      shipping_cost = international_shipping_charge(weight)
    else
      raise "Unsupported location value!"
    end
    if (currency == "KRW")
      rate = Spree::CurrencyRate.find_by(target_currency: currency)
      return Spree::Money.new(rate.convert_to_won(shipping_cost).amount, { currency: currency }).to_html
    elsif (currency == "USD")
      return Spree::Money.new(shipping_cost, { currency: currency }).to_html
    end
  end

  def total_weight(contents)
    contents.inject(0) do |weight, item|
      weight += item.quantity * default_weight(item.variant.weight)
    end.ceil
  end

  private

  def default_weight(weight)
    weight > 0.0 ? weight : preferred_default_weight
  end

  def compute_product_weight(product)
    weight = if product.variants.present?
      product.variants.maximum(:weight)
    else
      product.master.weight
    end
    default_weight(weight).ceil
  end
end
