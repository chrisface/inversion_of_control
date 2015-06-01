require "inversion_of_control/version"
require "inversion_of_control/configuration"
require "inversion_of_control/dsl"
require "inversion_of_control/builder"
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

  def self.resolve_dependency(dependency)
    resolved_dependency = @configuration.dependencies[dependency]

    # Try and find the dependency by name when missing if the config is turned on
    if resolved_dependency.nil? && @configuration.auto_resolve_unregistered_dependency
      resolved_dependency = self.resolve_dependency_by_name(dependency)
    end

    raise "un-registered dependency: #{dependency}" if resolved_dependency.nil?

    resolved_dependency = prepare_resolved_dependency(resolved_dependency)

    resolved_dependency
  end

  def self.resolve_dependency_by_name(dependency)
    class_name = "#{dependency}"
        .split("_").each {|s| s.capitalize! }.join("")

    Object.const_get(class_name)
  end

  def self.prepare_resolved_dependency(resolved_dependency)

    instantiate_dependencies = @configuration.instantiate_dependencies

    if resolved_dependency.is_a?(Hash)
      prepared_dependency = resolved_dependency[:dependency]
      instantiate_dependencies = resolved_dependency[:instantiate] unless resolved_dependency[:instantiate].nil?
    else
      prepared_dependency = resolved_dependency
    end

    if prepared_dependency.is_a?(Class) && instantiate_dependencies
      if prepared_dependency.ancestors.include?(InversionOfControl)
        prepared_dependency = prepared_dependency.build
      else
        prepared_dependency = prepared_dependency.new
      end
    end

    prepared_dependency
  end

  def self.register_dependency(dependency_name, dependency)
    @configuration.dependencies[dependency_name] = dependency
  end

  def self.included(klass)
    klass.extend(InversionOfControl::DSL)
    klass.extend(InversionOfControl::Builder)
    dependency_analyzer.track_class(klass)
  end

  def inject_dependency(dependency, resolved_dependency)
    self.instance_variable_set("@#{dependency}", resolved_dependency)
  end

  def inject_dependencies(dependencies = self.class.resolve_dependencies_from_class)
    dependencies.each do |dependency, resolved_dependency|
      self.inject_dependency(dependency, resolved_dependency)
    end
  end
end


