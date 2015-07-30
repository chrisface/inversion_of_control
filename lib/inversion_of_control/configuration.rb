module InversionOfControl
  class Configuration
    attr_accessor :dependencies
    attr_accessor :auto_resolve_unregistered_dependency
    attr_accessor :instantiate_dependencies
    attr_accessor :inject_on_initialize

    def initialize
      @dependencies = {}
      @auto_resolve_unregistered_dependency = false
      @instantiate_dependencies = false
      @inject_on_initialize = false
    end
  end
end
