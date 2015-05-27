require 'spec_helper'

describe InversionOfControl::Builder do
  describe ".build" do

    let(:dummy_class) do
      Class.new do
        include InversionOfControl
      end
    end

    context "with no parameters" do
      it "instantiates the class" do
        dummy_instance = dummy_class.build
        expect(dummy_instance.class).to be(dummy_class)
      end
    end

    context "with parameters" do

      let(:dummy_class) do
        Class.new do
          include InversionOfControl
          def initialize(param_1, param_2) end
        end
      end

      let(:params) { ["one", "two"] }

      before(:each) { allow(dummy_class).to receive(:new).and_call_original }

      it "instantiates the class with params" do
        dummy_instance = dummy_class.build(*params)
        expect(dummy_instance.class).to be(dummy_class)

        expect(dummy_class).to have_received(:new).with(*params)
      end
    end

    context "with keyword arguments" do

      let(:dummy_class) do
        Class.new do
          include InversionOfControl
          def initialize(param_1:, param_2:) end
        end
      end

      let(:params) { { param_1: "one", param_2: "two" } }

      before(:each) { allow(dummy_class).to receive(:new).and_call_original }

      it "instantiates the class with keyword arguments" do
        dummy_instance = dummy_class.build(params)
        expect(dummy_instance.class).to be(dummy_class)

        expect(dummy_class).to have_received(:new).with(params)
      end
    end

    context "with a block" do

      let(:dummy_class) do
        Class.new do
          include InversionOfControl
          def initialize(&block)
            yield
          end
        end
      end

      let(:block_hook) { double("block_hook", hooked: true) }

      it "instantiates the class with a block" do
        dummy_instance = dummy_class.build do
          block_hook.hooked
        end

        expect(dummy_instance.class).to be(dummy_class)
        expect(block_hook).to have_received(:hooked)
      end
    end

    context "with configured dependencies" do
      let(:resloved_dependency) { double() }

      before(:each) do
        InversionOfControl.configure do |config|
          config.dependencies[:a_dependency] = resloved_dependency
        end
      end

      let(:dummy_class) do
        Class.new do
          include InversionOfControl
          inject(:a_dependency)
        end
      end

      let(:dummy_instance) { dummy_class.build }

      it "injects dependencies" do
        expect(dummy_instance.a_dependency).to eq(resloved_dependency)
      end
    end
  end
end
