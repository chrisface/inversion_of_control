module InversionOfControl
  module Builder
    def build(*params, **keyword_args, &block)
      overriden_dependencies = resolve_dependencies_from_keywords!(keyword_args)

      if keyword_args.empty?
        class_instance = self.new(*params, &block)
      else
        class_instance = self.new(*params, **keyword_args, &block)
      end

      overriden_dependencies.merge!(_root: class_instance)

      resolved_dependencies = resolve_dependencies_from_class(
        existing_resolved_dependencies: overriden_dependencies
      )

      class_instance.inject_dependencies(resolved_dependencies)

      class_instance
    end

    def resolve_dependencies_from_keywords!(keyword_args)
      resolved_dependencies = keyword_args.select do |arg_name, arg_value|
        @dependencies.include?(arg_name)
      end

      keyword_args.reject! do |arg_name|
        @dependencies.include?(arg_name)
      end

      resolved_dependencies
    end

    def resolve_dependencies_from_class(existing_resolved_dependencies: {})
      resolved_dependencies = @dependencies.inject({}) do |resolved_dependencies, dependency|
        resolved_dependency = InversionOfControl.resolve_dependency(dependency, existing_resolved_dependencies)

        resolved_dependencies[dependency] = resolved_dependency
        resolved_dependencies
      end
    end
  end
end
