def jruby?
  RUBY_PLATFORM == "java"
end

require "simplecov"

SimpleCov.start do
  add_filter "/test"
  percent = jruby? ? 91.38 : 93.16
  minimum_coverage(percent)
end

require "multi_xml"
require "minitest/autorun"
