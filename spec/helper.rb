require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start

require 'multi_xml'
require 'rspec'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def jruby?(platform = RUBY_PLATFORM)
  "java" == platform
end

def rubinius?(platform = defined?(RUBY_ENGINE) && RUBY_ENGINE)
  "rbx" == platform
end
