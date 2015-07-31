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
      before(:each) do
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
    context "when the dependency analyzer was tracking classes" do
      before(:each) do
        described_class.dependency_analyzer.track_class(Class)
      end

      it "resets the tracked classes" do
        expect(described_class.dependency_analyzer.tracked_classes).to match_array(Class)

        described_class.reset

        expect(described_class.dependency_analyzer.tracked_classes).to be_empty
      end
    end
  end

  describe ".included" do
    context "when included into a class" do

      let!(:dummy_class) do
        Class.new do
          include InversionOfControl
          inject_dependencies()
        end
      end

      it "adds the dsl methods to the class" do
        expect(dummy_class).to respond_to(:inject_dependencies)
      end

      it "adds the assemble method for instantiation" do
        expect(dummy_class).to respond_to(:assemble)
      end

      it "tracks the class in the dependency analyzer" do
        da = InversionOfControl.dependency_analyzer
        expect(da.tracked_classes).to match_array(dummy_class)
      end
    end
  end

  describe ".resolve_dependency" do
    context "when the dependency is registered in config" do
      let(:resolved_dependency) { double() }

      before(:each) do
        described_class.configure do |config|
          config.dependencies[:a_dependency] = resolved_dependency
        end
      end

      it "returns the dependency that was registered" do
        expect(described_class.resolve_dependency(:a_dependency)).to eq(resolved_dependency)
      end
    end

    context "when the dependency is not registered in config" do
      before(:each) do
        described_class.configure do |config|
          config.auto_resolve_unregistered_dependency = auto_resolve
        end
      end

      context "and auto_resolve_unregistered_dependency config option is OFF" do
        let(:auto_resolve) { false }

        it "raises an un-registered dependency error" do
          expected_error = "un-registered dependency: unregistered"
          expect { described_class.resolve_dependency(:unregistered) }.to raise_error(expected_error)
        end
      end

      context "and the auto_resolve_unregistered_dependency config option is ON" do
        let(:auto_resolve) { true }

        it "resolves the dependency based on the name of the dependency" do
          resolved_dependency = described_class.resolve_dependency(:test_dependency)
          expect(resolved_dependency).to eq(TestDependency)
        end
      end
    end
  end

  describe ".resolve_dependency_by_name" do
    it "finds a dependency by name" do
      resolved_dependency = described_class.resolve_dependency_by_name(:test_dependency)
      expect(resolved_dependency).to eq(TestDependency)
    end
  end

  describe ".register_dependency" do
    let(:dependency_name) { :a_dependency }
    let(:dependency) { double }

    it "it registers the dependency" do
      expected_error = "un-registered dependency: #{dependency_name}"
      expect { described_class.resolve_dependency(dependency_name) }.to raise_error(expected_error)

      described_class.register_dependency(dependency_name, dependency)
      described_class.resolve_dependency(dependency_name)
    end
  end

  describe ".prepare_resolved_dependency" do
    before(:each) do
      described_class.configure do |config|
        config.instantiate_dependencies = instantiate_dependencies
      end
    end

    let(:instantiate_dependencies) { false }

    context "when the dependency is a class" do
      let(:resolved_dependency) {
        Class.new
      }
      context "and the instantiate_dependencies config option is ON" do
        let(:instantiate_dependencies) { true }

        context "and the class does not include InversionOfControl" do
          it "instantiates the Class" do
            prepared_dependency = described_class.prepare_resolved_dependency(resolved_dependency)
            expect(prepared_dependency.class).to eq(resolved_dependency)
          end
        end
      end

      context "and the instantiate_dependencies config option is OFF" do
        let(:instantiate_dependencies) { false }

        it "does not instantiatethe class" do
          prepared_dependency = described_class.prepare_resolved_dependency(resolved_dependency)
          expect(prepared_dependency).to eq(resolved_dependency)
        end
      end
    end

    context "when the dependency is configured with a Hash" do
      let(:resolved_dependency) {
        Class.new do
          include InversionOfControl
        end
      }

      let(:dependency_configuration) {
        {
          dependency: resolved_dependency
        }
      }

      it "retreives the dependency from the Hash configuration" do
        prepared_dependency = described_class.prepare_resolved_dependency(dependency_configuration)
        expect(prepared_dependency).to eq(resolved_dependency)
      end

      context "and the config option instantiate differs to the default" do
        let(:dependency_configuration) {
          {
            dependency: resolved_dependency,
            instantiate: true
          }
        }

        it "the dependency configuration takes precedence" do
          prepared_dependency = described_class.prepare_resolved_dependency(dependency_configuration)
          expect(prepared_dependency.class).to eq(resolved_dependency)
        end
      end
    end

    context "when the dependency is neither a hash or class" do
      let(:resolved_dependency) { "I'm a dependency" }

      it "no preparation is performed" do
        prepared_dependency = described_class.prepare_resolved_dependency(resolved_dependency)
        expect(prepared_dependency).to eq(resolved_dependency)
      end
    end
  end

  describe "#inject_dependency" do
    let(:dummy_class) do
      Class.new do
        include InversionOfControl
        inject_dependencies(:a_dependency)
      end
    end

    # Using the .assemble method would trigger automatic injection, we don't want
    # that for this test as we're testing the injection itself
    let(:dummy_instance) { dummy_class.new }

    let(:a_dependency_resolved) { double }

    it "injects the dependency" do
      dummy_instance.inject_dependency(:a_dependency, a_dependency_resolved)
      expect(dummy_instance.a_dependency).to eq(a_dependency_resolved)
    end
  end

  describe "#inject_dependencies" do
    let(:dummy_class) do
      Class.new do
        include InversionOfControl
        inject_dependencies(:a_dependency, :b_dependency)
      end
    end

    # Using the .assemble method would trigger automatic injection, we don't want
    # that for this test as we're testing the injection itself
    let(:dummy_instance) { dummy_class.new}

    let(:a_dependency_resolved) { double }
    let(:b_dependency_resolved) { double }

    it "injects the dependency" do
      dummy_instance.inject_dependencies(
        a_dependency: a_dependency_resolved,
        b_dependency: b_dependency_resolved
      )

      expect(dummy_instance.a_dependency).to eq(a_dependency_resolved)
      expect(dummy_instance.b_dependency).to eq(b_dependency_resolved)
    end
  end
end
