require 'spec_helper'

describe InversionOfControl::Configuration do

  it "has an empty dependency list by default" do
    expect(subject.dependencies).to eq({})
  end

end
