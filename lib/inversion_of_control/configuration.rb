module InversionOfControl
  class Configuration
    attr_accessor :dependencies
    attr_accessor :auto_resolve_unregistered_dependency
    attr_accessor :instantiate_dependencies

    def initialize
      @dependencies = {}
      @auto_resolve_unregistered_dependency = false
      @instantiate_dependencies = false
    end
  end
end
