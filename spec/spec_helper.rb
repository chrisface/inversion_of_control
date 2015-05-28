$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'byebug'
require 'test_dependency'
require 'inversion_of_control'

RSpec.configure do |config|

  config.before(:example) do
    InversionOfControl.reset
  end
end
