require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]

def jruby?(platform = RUBY_PLATFORM)
  'java' == platform
end

def rubinius?(platform = defined?(RUBY_ENGINE) && RUBY_ENGINE)
  'rbx' == platform
end

SimpleCov.start do
  add_filter '/spec/'
  percent = jruby? ? 91.29 : 91.96
  minimum_coverage(percent)
end

require 'multi_xml'
require 'rspec'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
