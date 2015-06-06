module InversionOfControl
  module Builder
    def build(*params, **keyword_args, &block)
      overriden_dependencies = resolve_dependencies_from_keywords!(keyword_args)

      if keyword_args.empty?
        class_instance = self.new(*params, &block)
      else
        class_instance = self.new(*params, **keyword_args, &block)
      end

      class_dependencies = resolve_dependencies_from_class(exclude: overriden_dependencies.keys)

      # Class dependencies need to be prepared for injection. Overriden dependencies are assumed to already be preapred
      prepared_dependencies = {}
      class_dependencies.each do |resolved_dependency_name, resolved_dependency|
        prepared_dependency = InversionOfControl.prepare_resolved_dependency(resolved_dependency)
        prepared_dependencies[resolved_dependency_name] = prepared_dependency
      end

      prepared_dependencies.merge!(overriden_dependencies)

      class_instance.inject_dependencies(prepared_dependencies)

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

    def resolve_dependencies_from_class(exclude: [])
      resolved_dependencies = (@dependencies - exclude).inject({}) do |resolved_dependencies, dependency|
        resolved_dependency = InversionOfControl.resolve_dependency(dependency)

        resolved_dependencies[dependency] = resolved_dependency
        resolved_dependencies
      end
    end
  end
end
