module InversionOfControl
  class Configuration
    attr_accessor :dependencies
    attr_accessor :auto_resolve_unregistered_dependency

    def initialize
      @dependencies = {}
      @auto_resolve_unregistered_dependency = false
    end
  end
end
