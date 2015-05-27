module InversionOfControl
  module DSL

    attr_accessor :dependencies

    def self.extended(klass)
      klass.dependencies = []
    end

    def inject(*dependencies)
      @dependencies = dependencies
      @dependencies.each { |dependency| self.send(:attr_accessor, dependency) }
    end
  end
end
