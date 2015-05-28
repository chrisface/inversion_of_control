require "inversion_of_control/version"
require "inversion_of_control/configuration"
require "inversion_of_control/dsl"
require "inversion_of_control/builder"

module InversionOfControl

  class << self
    attr_accessor :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration) if block_given?
  end

  def self.reset
    @configuration = Configuration.new
  end

  def self.resolve_dependency(dependency)
    resolved_dependency = @configuration.dependencies[dependency]

    # Try and find the dependency by name when missing if the config is turned on
    if resolved_dependency.nil? && @configuration.auto_resolve_unregistered_dependency
      resolved_dependency = self.resolve_dependency_by_name(dependency)
    end

    raise "un-registered dependency: #{dependency}" if resolved_dependency.nil?

    resolved_dependency
  end

  def self.resolve_dependency_by_name(dependency)
    class_name = "#{dependency}"
        .split("_").each {|s| s.capitalize! }.join("")

    Object.const_get(class_name)
  end

  def self.included(klass)
    klass.extend(InversionOfControl::DSL)
    klass.extend(InversionOfControl::Builder)
  end

  def inject_dependency(dependency, resolved_dependency)
    self.instance_variable_set("@#{dependency}", resolved_dependency)
  end

  def inject_dependencies(dependencies)
    dependencies.each do |dependency, resolved_dependency|
      self.inject_dependency(dependency, resolved_dependency)
    end
  end
end


