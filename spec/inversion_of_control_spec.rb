require 'spec_helper'

describe InversionOfControl do
  it 'has a version number' do
    expect(InversionOfControl::VERSION).not_to be nil
  end

  describe "#configure" do
    let(:configured_dependencies) { {configured: "dependency"} }

    before(:each) do
      described_class.configure do |config|
        config.dependencies = configured_dependencies
      end
    end

    it "sets the configuration" do
      config = described_class.configuration

      expect(config.dependencies).to eq(configured_dependencies)
    end
  end

  describe ".reset" do
    context "when there was config already set" do
      before :each do
        described_class.configure do |config|
          config.dependencies = {data: "here"}
        end
      end

      it "resets the configuration" do
        described_class.reset

        config = described_class.configuration

        expect(config.dependencies).to eq({})
      end
    end
  end

  describe ".included" do
    context "when included into a class" do

      let(:dummy_class) do
        Class.new do
          include InversionOfControl
        end
      end

      it "adds the dsl methods to the class" do
        expect(dummy_class).to respond_to(:inject)
      end

      it "adds the build method for instantiation" do
        expect(dummy_class).to respond_to(:build)
      end
    end
  end

  describe ".resolve_dependency" do
    context "when the dependency is registered in config" do
      let(:resloved_dependency) { double() }

      before(:each) do
        described_class.configure do |config|
          config.dependencies[:a_dependency] = resloved_dependency
        end
      end

      it "returns the dependency that was registered" do
        expect(described_class.resolve_dependency(:a_dependency)).to eq(resloved_dependency)
      end
    end

    context "when the dependency is not registered in config" do
      it "raises an un-registered dependency error" do
        expected_error = "un-registered dependency: unregistered"
        expect { described_class.resolve_dependency(:unregistered) }.to raise_error(expected_error)
      end
    end
  end

  describe "#inject_dependency" do
    let(:dummy_class) do
      Class.new do
        include InversionOfControl
        inject(:a_dependency)
      end
    end

    # Using the .build method would trigger automatic injection, we don't want
    # that for this test as we're testing the injection itself
    let(:dummy_instance) { dummy_class.new }

    let(:a_dependency_resolved) { double }

    it "injects the dependency" do
      expect(dummy_instance.a_dependency).to be_nil
      dummy_instance.inject_dependency(:a_dependency, a_dependency_resolved)
      expect(dummy_instance.a_dependency).to eq(a_dependency_resolved)
    end
  end

  describe "#inject_dependencies" do
    let(:dummy_class) do
      Class.new do
        include InversionOfControl
        inject(:a_dependency, :b_dependency)
      end
    end

    # Using the .build method would trigger automatic injection, we don't want
    # that for this test as we're testing the injection itself
    let(:dummy_instance) { dummy_class.new}

    let(:a_dependency_resolved) { double }
    let(:b_dependency_resolved) { double }

    it "injects the dependency" do
      expect(dummy_instance.a_dependency).to be_nil
      expect(dummy_instance.b_dependency).to be_nil

      dummy_instance.inject_dependencies(
        a_dependency: a_dependency_resolved,
        b_dependency: b_dependency_resolved
      )

      expect(dummy_instance.a_dependency).to eq(a_dependency_resolved)
      expect(dummy_instance.b_dependency).to eq(b_dependency_resolved)
    end
  end
end
