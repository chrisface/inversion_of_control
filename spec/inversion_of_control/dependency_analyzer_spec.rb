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
end
