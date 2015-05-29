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
          def initialize(param_1, param_2, param_3) end
        end
      end

      before(:each) { allow(dummy_class).to receive(:new).and_call_original }

      let(:param_1) { "one" }
      let(:param_2) { "two" }
      let(:param_3) { "three" }

      context "and no dependency overrides" do
        it "instantiates the class with params", focus: true do
          dummy_instance = dummy_class.build(param_1, param_2, param_3)
          expect(dummy_instance.class).to be(dummy_class)

          expect(dummy_class).to have_received(:new).with(param_1, param_2, param_3)
        end
      end

      context "with dependency overrides" do
        let(:params) { ["one", "two"] }

        let(:dummy_class) do
          Class.new do
            include InversionOfControl
            inject(:dependency_a, :dependency_b)
            def initialize(param_1, param_2, param_3:) end
          end
        end

        let(:resloved_dependency_a) { double }
        let(:resloved_dependency_b) { double }

        let(:overriden_dependency_a) { double }
        let(:overriden_dependency_b) { double }

        before(:each) do
          InversionOfControl.configure do |config|
            config.dependencies[:dependency_a] = resloved_dependency_a
            config.dependencies[:dependency_b] = resloved_dependency_b
          end
        end

        it "instantiates the class with the params" do
          dummy_instance = dummy_class.build(
            param_1,
            param_2,
            param_3: param_3,
            dependency_a: overriden_dependency_a,
            dependency_b: overriden_dependency_b
          )
          expect(dummy_instance.class).to be(dummy_class)

          expect(dummy_class).to have_received(:new).with(param_1, param_2, {param_3: param_3})
        end

        it "overrides the dependency" do
          dummy_instance = dummy_class.build(
            param_1,
            param_2,
            param_3: param_3,
            dependency_a: overriden_dependency_a,
            dependency_b: overriden_dependency_b
          )
          expect(dummy_instance.class).to be(dummy_class)

          expect(dummy_instance.dependency_a).to eq(overriden_dependency_a)
          expect(dummy_instance.dependency_b).to eq(overriden_dependency_b)
        end
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
