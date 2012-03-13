unless ENV['CI']
  require 'simplecov'
  SimpleCov.start
end
require 'multi_xml'
