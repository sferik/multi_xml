require 'simplecov'
SimpleCov.start do
  add_group 'Libraries', 'lib'
end

require File.expand_path('../../lib/multi_xml', __FILE__)

require 'rspec'
