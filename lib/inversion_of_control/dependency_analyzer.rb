module InversionOfControl
  class DependencyAnalyzer

    attr_accessor :tracked_classes, :dependency_trees

    def initialize
      @tracked_classes = []
    end

    def track_class(klass)
      @tracked_classes << klass
    end
  end
end
