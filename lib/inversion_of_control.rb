require "inversion_of_control/version"
require "inversion_of_control/configuration"
require "inversion_of_control/dsl"
require "inversion_of_control/assembler"
require "inversion_of_control/dependency_analyzer"

module InversionOfControl

  class << self
    attr_accessor :configuration, :dependency_analyzer
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration) if block_given?
  end

  def self.reset
    @configuration = Configuration.new
    @dependency_analyzer = InversionOfControl::DependencyAnalyzer.new
  end

  def self.dependency_analyzer
    @dependency_analyzer ||= InversionOfControl::DependencyAnalyzer.new
  end

  def self.resolve_dependency(dependency, resolved_dependencies={})
    resolved_dependency = configuration.dependencies[dependency]

    # Try and find the dependency by name when missing if the config is turned on
    if resolved_dependency.nil? && configuration.auto_resolve_unregistered_dependency
      resolved_dependency = self.resolve_dependency_by_name(dependency)
    end

    raise "un-registered dependency: #{dependency}" if resolved_dependency.nil?

    # If the dependency has alreay been resolved, then re-use it.
    if resolved_dependencies.keys.include?(dependency)
      resolved_dependency = resolved_dependencies[dependency]
    else
      resolved_dependency = prepare_resolved_dependency(resolved_dependency)

      # If the root is of the same class as the dependency. It can be assumed
      # that there is a circular dependency back to the root. Re-name the root
      # Now that we have discovered what it's name is.
      root_resolved_dependency = resolved_dependencies[:_root]
      if root_resolved_dependency && resolved_dependency.class == root_resolved_dependency.class
        resolved_dependencies[dependency] = root_resolved_dependency
        resolved_dependencies.delete(:_root)
        resolved_dependency = root_resolved_dependency
      else
        resolved_dependencies[dependency] = resolved_dependency
      end
    end

    # Resolve any child dependencies
    if resolved_dependency.class.ancestors.include?(InversionOfControl)
      resolved_dependency.class.dependencies.each do |child_dependency|

        # Create the child dependency if it has not already been resolved
        unless resolved_dependencies.keys.include?(child_dependency)
          resolved_child_dependency = self.resolve_dependency(child_dependency, resolved_dependencies)
          resolved_dependencies[child_dependency] = resolved_child_dependency
        end
      end
    end

    # Inject dependencies after they have have been resolved
    if resolved_dependency.class.ancestors.include?(InversionOfControl)
      required_resolved_dependencies = resolved_dependencies.select do |dependency_name, available_resolved_dependency|
        resolved_dependency.class.dependencies.include?(dependency_name)
      end

      resolved_dependency.inject_dependencies(required_resolved_dependencies)
    end

    resolved_dependency
  end

  def self.resolve_dependency_by_name(dependency)
    class_name = "#{dependency}"
        .split("_").each {|s| s.capitalize! }.join("")

    Object.const_get(class_name)
  end

  def self.prepare_resolved_dependency(resolved_dependency)

    instantiate_dependencies = configuration.instantiate_dependencies

    if resolved_dependency.is_a?(Hash)
      prepared_dependency = resolved_dependency[:dependency]
      instantiate_dependencies = resolved_dependency[:instantiate] unless resolved_dependency[:instantiate].nil?
    else
      prepared_dependency = resolved_dependency
    end

    if prepared_dependency.is_a?(Class) && instantiate_dependencies
      prepared_dependency = prepared_dependency.new
    end

    prepared_dependency
  end

  def self.register_dependency(dependency_name, dependency)
    configuration.dependencies[dependency_name] = dependency
  end

  def self.included(klass)
    klass.extend(InversionOfControl::DSL)
    klass.extend(InversionOfControl::Assembler)
  end

  def inject_dependency(dependency, resolved_dependency)
    self.class.send(:attr_accessor, dependency)
    self.public_send("#{dependency}=", resolved_dependency)
  end

  def inject_dependencies(dependencies = self.class.resolve_dependencies_from_class)
    dependencies.each do |dependency, resolved_dependency|
      self.inject_dependency(dependency, resolved_dependency)
    end
  end
end
