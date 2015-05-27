module InversionOfControl
  class Configuration
    attr_accessor :dependencies

    def initialize
      @dependencies = {}
    end
  end
end
