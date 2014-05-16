require 'spec_helper'

module Spree
  module Calculator::Shipping
    describe Ohmyzip do
      before do
        Spree::CurrencyRate.create(:rate => 1050, :base_currency => 'USD', :target_currency => 'KRW')
      end

      let(:calculator) { described_class.new }

      let(:variant1) { double("Variant", 
        weight: 1, width: 1, depth: 1, height: 1, price: 4) }
      let(:variant2) { double("Variant", 
        weight: 2, width: 1, depth: 1, height: 1, price: 6) }

      let(:package) { 
        double(
          Stock::Package,
          order: mock_model(Order),
          contents: [Stock::Package::ContentItem.new(1,variant1, 1)]
        ) 
      }

      let(:package2) {
        double(
          Stock::Package,
          order: mock_model(Order),
          contents: [Stock::Package::ContentItem.new(1,variant1, 2),
            Stock::Package::ContentItem.new(1,variant2, 1)]
        )
      }

      it "returns correct description" do
        expect(calculator.description).to eq 'Ohmyzip Shipping Calculator'
      end

      it "correctly calculates weight for one item" do
        calculator.total_weight(package.contents).should == 1
      end

      it "correctly calculates weight for a package with multiple items" do
        calculator.total_weight(package2.contents).should == 4
      end

      it "correctly calculates shipping cost with one item in package" do
        calculator.compute_package(package).should == 8.5 * 1050 # weighs 1 lb
      end
      
      it "correctly calculates shipping cost with multiple items in package" do
        calculator.compute_package(package2).should == 14.5 * 1050 # weighs 4 lbs
      end
    end
  end
end
