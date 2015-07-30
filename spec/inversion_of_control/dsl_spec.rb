require 'spec_helper'

describe InversionOfControl::DSL do
  describe ".inject" do

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
          inject()
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
          inject(:example_dependency)
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
          inject(:example_dependency_1, :example_dependency_2)
        end
      end

      it "registers the dependencies on the class" do
        expect(dummy_class.dependencies).to match_array([:example_dependency_1, :example_dependency_2])
      end
    end
  end
end
