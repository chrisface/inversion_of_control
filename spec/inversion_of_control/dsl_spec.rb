require 'spec_helper'

describe InversionOfControl::DSL do
  describe ".inject_dependencies" do

    context "with no dependencies implicitly" do
      let(:dummy_class) do
        Class.new do
          extend InversionOfControl::DSL
        end
      end

      it "does not register any dependencies on the class" do
        expect(dummy_class.dependencies).to be_empty
      end
    end

    context "with no dependencies explicitly" do
      let(:dummy_class) do
        Class.new do
          extend InversionOfControl::DSL
          inject_dependencies()
        end
      end

      it "does not register any dependencies on the class" do
        expect(dummy_class.dependencies).to be_empty
      end
    end

    context "with one dependency" do
      let(:dummy_class) do
        Class.new do
          extend InversionOfControl::DSL
          inject_dependencies(:example_dependency)
        end
      end

      it "registers the dependency on the class" do
        expect(dummy_class.dependencies).to match_array([:example_dependency])
      end
    end

    context "with multiple dependencies" do
      let(:dummy_class) do
        Class.new do
          extend InversionOfControl::DSL
          inject_dependencies(:example_dependency_1, :example_dependency_2)
        end
      end

      it "registers the dependencies on the class" do
        expect(dummy_class.dependencies).to match_array([:example_dependency_1, :example_dependency_2])
      end
    end

    context "tracking dependencies" do
      before(:each) do
        if defined?(analyze_dependencies)
          InversionOfControl.configuration.analyze_dependencies = analyze_dependencies
        end
      end

      let!(:dummy_class) do
        Class.new do
          include InversionOfControl
          inject_dependencies()
        end
      end

      let(:dependency_analyzer) { InversionOfControl.dependency_analyzer }

      context "by default" do
        it "does not track the class in the dependency analyzer" do
          expect(dependency_analyzer.tracked_classes).to be_empty
        end
      end

      context "with dependency tracking turned on" do
        let(:analyze_dependencies) { true }
        it "tracks the class in the dependency analyzer" do
          InversionOfControl.configuration.analyze_dependencies = true
          expect(dependency_analyzer.tracked_classes).to match_array(dummy_class)
        end
      end
    end
  end
end
