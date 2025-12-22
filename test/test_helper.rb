def jruby?
  RUBY_PLATFORM == "java"
end

require "simplecov"

SimpleCov.start do
  add_filter "/test"
  minimum_coverage(100)
end

require "multi_xml"
require "minitest/autorun"
