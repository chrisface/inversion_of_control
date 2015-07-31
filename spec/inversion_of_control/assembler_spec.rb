require 'spec_helper'

describe InversionOfControl::Assembler do
  describe "#initialize" do
    let(:dummy_class) do
      Class.new do
        include InversionOfControl
        inject_dependencies(:dependency_a, :dependency_b)
      end
    end

    let(:resolved_dependency_a) { double }
    let(:resolved_dependency_b) { double }

    before(:each) do
      InversionOfControl.configure do |config|
        config.dependencies[:dependency_a] = resolved_dependency_a
        config.dependencies[:dependency_b] = resolved_dependency_b
        config.inject_on_initialize = true
      end
    end

    it "injects the dependencies" do
      dummy_instance = dummy_class.new
      expect(dummy_instance.class).to be(dummy_class)

      expect(dummy_instance.dependency_a).to eq(resolved_dependency_a)
      expect(dummy_instance.dependency_b).to eq(resolved_dependency_b)
    end
  end

  describe ".assemble" do

    let(:dummy_class) do
      Class.new do
        include InversionOfControl
      end
    end

    context "with no parameters" do
      it "instantiates the class" do
        dummy_instance = dummy_class.assemble
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
          dummy_instance = dummy_class.assemble(param_1, param_2, param_3)
          expect(dummy_instance.class).to be(dummy_class)

          expect(dummy_class).to have_received(:new).with(param_1, param_2, param_3)
        end
      end

      context "with dependency overrides" do
        let(:params) { ["one", "two"] }

        let(:dummy_class) do
          Class.new do
            include InversionOfControl
            inject_dependencies(:dependency_a, :dependency_b)
            def initialize(param_1, param_2, param_3:) end
          end
        end

        let(:resolved_dependency_a) { double }
        let(:resolved_dependency_b) { double }

        let(:overriden_dependency_a) { double }
        let(:overriden_dependency_b) { double }

        before(:each) do
          InversionOfControl.configure do |config|
            config.dependencies[:dependency_a] = resolved_dependency_a
            config.dependencies[:dependency_b] = resolved_dependency_b
          end
        end

        it "instantiates the class with the params" do
          dummy_instance = dummy_class.assemble(
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
          dummy_instance = dummy_class.assemble(
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
        dummy_instance = dummy_class.assemble(params)
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
        dummy_instance = dummy_class.assemble do
          block_hook.hooked
        end

        expect(dummy_instance.class).to be(dummy_class)
        expect(block_hook).to have_received(:hooked)
      end
    end

    context "with configured dependencies" do
      let(:resolved_dependency) { double() }

      before(:each) do
        InversionOfControl.configure do |config|
          config.dependencies[:a_dependency] = resolved_dependency
        end
      end

      let(:dummy_class) do
        Class.new do
          include InversionOfControl
          inject_dependencies(:a_dependency)
        end
      end

      let(:dummy_instance) { dummy_class.assemble }

      it "injects dependencies" do
        expect(dummy_instance.a_dependency).to eq(resolved_dependency)
      end
    end

    context "with a circular dependencies" do

      before(:each) do
        InversionOfControl.configure do |config|
          config.auto_resolve_unregistered_dependency = true
          config.instantiate_dependencies = true
        end
      end

      context "between two classes" do

        before(:each) do
          class DependencyA
            include InversionOfControl
            inject_dependencies(:dependency_b)
          end

          class DependencyB
            include InversionOfControl
            inject_dependencies(:dependency_a)
          end
        end

        after(:each) do
          [:DependencyA, :DependencyB ].each do |class_symbol|
            Object.send(:remove_const, class_symbol)
          end
        end

        it "injects the classes into each other" do
          dependency_a = DependencyA.assemble
          dependency_b = dependency_a.dependency_b
          dependency_a_circular = dependency_b.dependency_a

          expect(dependency_a).to eq(dependency_a_circular)
        end
      end

      context "through three classes" do
        before(:each) do
          class DependencyA
            include InversionOfControl
            inject_dependencies(:dependency_b)
          end

          class DependencyB
            include InversionOfControl
            inject_dependencies(:dependency_c)
          end

          class DependencyC
            include InversionOfControl
            inject_dependencies(:dependency_a)
          end
        end

        after(:each) do
          [:DependencyA, :DependencyB, :DependencyC ].each do |class_symbol|
            Object.send(:remove_const, class_symbol)
          end
        end

        it "injects the classes into each other" do
          dependency_a = DependencyA.assemble
          dependency_b = dependency_a.dependency_b
          dependency_c = dependency_b.dependency_c
          dependency_a_circular = dependency_c.dependency_a

          expect(dependency_a).to eq(dependency_a_circular)
        end
      end

      context "through three classes with a loop-back" do
        before(:each) do
          class DependencyA
            include InversionOfControl
            inject_dependencies(:dependency_b)
          end

          class DependencyB
            include InversionOfControl
            inject_dependencies(:dependency_c)
          end

          class DependencyC
            include InversionOfControl
            inject_dependencies(:dependency_a, :dependency_b, :dependency_d)
          end

          class DependencyD
          end
        end

        after(:each) do
          [:DependencyA, :DependencyB, :DependencyC, :DependencyD ].each do |class_symbol|
            Object.send(:remove_const, class_symbol)
          end
        end

        it "injects the classes into each other" do
          dependency_a = DependencyA.assemble
          dependency_b = dependency_a.dependency_b
          dependency_c = dependency_b.dependency_c
          dependency_a_circular = dependency_c.dependency_a
          dependency_b_circular = dependency_c.dependency_b

          expect(dependency_a).to eq(dependency_a_circular)
          expect(dependency_b).to eq(dependency_b_circular)
        end
      end
    end
  end
end
