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
    if weight > 7
      shipping_charge = (18.4 + (weight - 7) * 1.72).round(2)
    else
      @shipping_rate ||= [9.0, 9.0, 11.2, 13.0, 14.8, 16.9, 17.8, 18.4]
      shipping_charge = @shipping_rate[weight]
    end
    shipping_charge + preferred_snapshop_shipping_markup
  end

  def local_shipping_amount(product_or_order)
    # get an array of products to iterate on
    products = case product_or_order
      when Spree::Product then [product_or_order]
      when Spree::Order then product_or_order.line_items.map(&:product)
    end

    return nil if products.empty?

    products_by_merchant = products.group_by { |p| p.merchant }
    local_shipping_total = 0
    products_by_merchant.map do |merchant, products|
      merchant_total = products.sum(&:price).to_f
      case merchant
        when "gap", "bananarepublic"
          local_shipping_total += 7
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

  def compute_product_amount(product)
    if product.variants.present?
      weight = product.variants.maximum(:weight)
    else
      weight = product.master.weight
    end
    weight = weight > 0.0 ? weight / 100 : preferred_default_weight
    weight = weight.ceil

    international_shipping_charge(weight) + local_shipping_amount(product)
  end

  def total_weight(contents)
    weight = 0
    contents.each do |item|
      weight += item.quantity * (item.variant.weight > 0.0 ? item.variant.weight / 100 : preferred_default_weight)
    end
    weight.ceil
  end
end
