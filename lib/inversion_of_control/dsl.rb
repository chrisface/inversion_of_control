module InversionOfControl
  module DSL

    attr_accessor :dependencies

    def self.extended(klass)
      klass.dependencies = []
    end

    def inject(*dependencies)
      @dependencies = dependencies
    end
  end
end
