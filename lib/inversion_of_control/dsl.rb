module InversionOfControl
  module DSL

    attr_writer :dependencies

    def dependencies
      @dependencies || []
    end

    def inject_dependencies(*dependencies)
      InversionOfControl.dependency_analyzer.track_class(self)

      if dependencies.nil?
        self.ancestors.each_with_index do |ancestor, index|
          if ancestor.respond_to?(:dependencies)
            if ancestor.dependencies && ancestor.dependencies.any?
              # To prevent changing dependencies on the parent, we must dup
              self.dependencies += self.ancestors[index].kept_methods.dup
            end
          else
            break
          end
        end
      end

      @dependencies = dependencies.uniq
    end
  end
end
