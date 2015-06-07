require 'graphviz'
module InversionOfControl

  class Node
    attr_accessor :edges, :resolved_dependency, :dependency_name

    def initialize(resolved_dependency, dependency_name)
      @resolved_dependency = resolved_dependency
      @dependency_name = dependency_name
      @edges = []
    end

    def add_edge(edges)
      @edges << edges
    end

    def name
      resolved_dependency.to_s
    end

    def type
      resolved_dependency.class
    end
  end

  class DependencyAnalyzer
    attr_accessor :tracked_classes

    def initialize
      @tracked_classes = []
    end

    def track_class(klass)
      @tracked_classes << klass
    end

    def generate_graph(file_path)
      nodes = {}

      @tracked_classes.each do |klass|

        # Check to see if the dependency has already been found
        node = nodes[klass]

        unless node
          # The name of a dependency can only be resolved by a dependant
          node = Node.new(klass, "unknown")
          nodes[klass] = node
        end

        klass.resolve_dependencies_from_class.each do |dependency, resolved_dependency|

          # The dependency may have incorrectly been assumed to be a static Class
          # dependency based on the order of discovery
          if child_node = nodes[resolved_dependency]

            # If the dependency was already registered and had no name, set the name
            # now that we have discovered it via a dependency
            if child_node.dependency_name == "unknown"
              child_node.dependency_name = dependency
            end
          elsif child_node = nodes[resolved_dependency.class]
            # The dependency was mistaken for a static class dependency
            child_node.resolved_dependency = resolved_dependency

            nodes.delete(resolved_dependency.class)
            nodes[resolved_dependency] = child_node

            if child_node.dependency_name == "unknown"
              child_node.dependency_name = dependency
            end
          else
            child_node = Node.new(resolved_dependency, dependency)
            nodes[resolved_dependency] = child_node
          end

          node.add_edge(child_node)
        end
      end

      draw_graph(nodes, file_path)
    end

    def draw_graph(nodes, file_path)
      g = GraphViz.new(:G, :type => :digraph)
      drawn_nodes = Hash.new{ |hash, key| hash[key] = g.add_nodes("#{key.dependency_name}\n#{key.type}\n#{key.name}") }

      nodes.values.each do |from_node|
        gviz_node_from = drawn_nodes[from_node]

        from_node.edges.each do |to_node|
          gviz_node_to = drawn_nodes[to_node]
          g.add_edges(gviz_node_from, gviz_node_to)
        end
      end

      g.output( :png => file_path )
    end
  end
end
