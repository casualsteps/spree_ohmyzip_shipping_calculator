module SpreeOhmyzipShippingCalculator
  class Engine < Rails::Engine
    isolate_namespace Spree
    engine_name 'spree_ohmyzip_shipping_calculator'

    config.autoload_paths += %W({#{config.root}/lib)

    initializer 'spree.register.calculators' do |app|
      require 'spree/calculator/shipping/ohmyzip_shipping_calculator'
      app.config.spree.calculators.shipping_methods << Spree::Calculator::Ohmyzip
    end
  end
end
