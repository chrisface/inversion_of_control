require 'spec_helper'

describe InversionOfControl::DependencyAnalyzer do

  context "#track_class" do
    context "when a class is tracked" do
      before(:each) { subject.track_class(Class) }

      it "becomes part of the tracked classes" do
        expect(subject.tracked_classes).to match_array(Class)
      end
    end
  end

  context "#generate_graph" do

    context "circular dependency" do
      context "between two classes" do
        before(:each) do
          class DependencyA
            include InversionOfControl
            inject(:dependency_b)
          end

          class DependencyB
            include InversionOfControl
            inject(:dependency_a)
          end

          InversionOfControl.configure do |config|
            config.auto_resolve_unregistered_dependency = true
          end
        end

        after(:each) do
          [:DependencyA, :DependencyB ].each do |class_symbol|
            Object.send(:remove_const, class_symbol)
          end
        end

        it "generates a graph for the cyclical dependency" do
          InversionOfControl.dependency_analyzer.generate_graph('tmp/cyclic_dependency_2_classes.png')
        end
      end

      context "through three classes" do
        before(:each) do
          class DependencyA
            include InversionOfControl
            inject(:dependency_b)
          end

          class DependencyB
            include InversionOfControl
            inject(:dependency_c)
          end

          class DependencyC
            include InversionOfControl
            inject(:dependency_a)
          end

          InversionOfControl.configure do |config|
            config.auto_resolve_unregistered_dependency = true
          end
        end

        after(:each) do
          [:DependencyA, :DependencyB, :DependencyC ].each do |class_symbol|
            Object.send(:remove_const, class_symbol)
          end
        end

        it "generates a graph for the cyclical dependency" do
          InversionOfControl.dependency_analyzer.generate_graph('tmp/cyclic_dependency_3_classes.png')
        end
      end

      context "with a loopback" do
        before(:each) do
          class DependencyA
            include InversionOfControl
            inject(:dependency_b)
          end

          class DependencyB
            include InversionOfControl
            inject(:dependency_c)
          end

          class DependencyC
            include InversionOfControl
            inject(:dependency_a, :dependency_b, :dependency_d)
          end

          class DependencyD
            include InversionOfControl
            inject(:dependency_b)
          end

          InversionOfControl.configure do |config|
            config.auto_resolve_unregistered_dependency = true
          end
        end

        after(:each) do
          [:DependencyA, :DependencyB, :DependencyC, :DependencyD ].each do |class_symbol|
            Object.send(:remove_const, class_symbol)
          end
        end

        it "generates a graph for the cyclical dependency" do
          InversionOfControl.dependency_analyzer.generate_graph('tmp/cyclic_dependency_loopback.png')
        end
      end
    end

    context "complex tree structure with constructed and static dependencies" do
      before(:each) do
        class UserRepository ; end
        class MailGun
          include InversionOfControl
          inject(:mail_api_key)
        end
        class OrderRepository ; end

        class UserService
          include InversionOfControl
          inject(:user_repository)
        end

        class OrderManager
          include InversionOfControl
          inject(:order_repository, :mail_service, :manager_config)
        end

        class UserOrders
          include InversionOfControl
          inject(:order_manager, :user_service)
        end

        InversionOfControl.configure do |config|
          config.auto_resolve_unregistered_dependency = true
          config.instantiate_dependencies = true
          config.dependencies = {
            mail_api_key: "1234",
            mail_service: {
              dependency: MailGun,
              instantiate: false
            },
            manager_config: {
              dependency: {
                auto_accept: true
              }
            }
          }
        end
      end

      after(:each) do
        test_classes = [:UserRepository, :MailGun, :OrderRepository, :UserService, :OrderManager, :UserOrders]
        test_classes.each do |class_symbol|
          Object.send(:remove_const, class_symbol)
        end
      end

      it "generates a graph for the complex tree" do
        InversionOfControl.dependency_analyzer.generate_graph('tmp/complex_tree.png')
      end
    end
  end
end
