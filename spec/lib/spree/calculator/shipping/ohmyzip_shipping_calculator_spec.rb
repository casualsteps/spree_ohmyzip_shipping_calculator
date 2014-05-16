require 'spec_helper'

module Spree
  module Calculator::Shipping
    describe Ohmyzip do

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
          contents: [Stock::Package::ContentItem.new(1,variant1, 1),
            Stock::Package::ContentItem.new(2,variant2, 2)]
        )
      }

      it "returns correct description" do
        expect(calculator.description).to eq 'Ohmyzip Shipping Calculator'
      end

      it "correctly calculates weight for a package with multiple items" do
        calculator.total_weight(package2).should == 3
      end

      it "correctly calculates shipping cost when weight is 1 lb" do
        calculator.compute_package(package).should == 8.5
      end
      
      it "correctly calculates shipping cost when weight is 2 lb" do
        calculator.compute_package(package).should == 10.5
      end

      it "correctly calculates shipping cost when weight is 3 lbs" do
        calculator.compute_package(package2).should == 12.5
      end
    end
  end
end
