module InversionOfControl
  module Builder
    def build(*args, &block)
      class_instance = self.new(*args, &block)

      resolved_dependencies = @dependencies.inject({}) do |resolved_dependencies, dependency|
        resolved_dependency = InversionOfControl.resolve_dependency(dependency)
        resolved_dependencies[dependency] = resolved_dependency
        resolved_dependencies
      end

      class_instance.inject_dependencies(resolved_dependencies)

      class_instance
    end
  end
end
