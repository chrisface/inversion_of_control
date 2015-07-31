module InversionOfControl
  module Assembler

    def assemble(*params, **keyword_args, &block)
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

    def self.extended(klass)
      klass.send(:define_method, :initialize_with_inject_dependencies) do |*params, **keyword_args, &block|
        if keyword_args.empty?
          initialize_without_inject_dependencies(*params, &block)
        else
          initialize_without_inject_dependencies(*params, **keyword_args, &block)
        end
        self.inject_dependencies(self.class.resolve_dependencies_from_class)
      end

      if InversionOfControl.configuration.inject_on_initialize
        klass.send(:alias_method, :initialize_without_inject_dependencies, :initialize)
        klass.send(:alias_method, :initialize, :initialize_with_inject_dependencies)
      end
    end

    def resolve_dependencies_from_keywords!(keyword_args)
      resolved_dependencies = keyword_args.select do |arg_name, arg_value|
        dependencies.include?(arg_name)
      end

      keyword_args.reject! do |arg_name|
        dependencies.include?(arg_name)
      end

      resolved_dependencies
    end

    def resolve_dependencies_from_class(existing_resolved_dependencies: {})
      dependencies.inject({}) do |resolved_dependencies, dependency|
        resolved_dependency = InversionOfControl.resolve_dependency(dependency, existing_resolved_dependencies)

        resolved_dependencies[dependency] = resolved_dependency
        resolved_dependencies
      end
    end
  end
end
