def jruby?(platform = RUBY_PLATFORM)
  'java' == platform
end

def rubinius?(platform = defined?(RUBY_ENGINE) && RUBY_ENGINE)
  'rbx' == platform
end

if RUBY_VERSION >= '1.9'
  require 'simplecov'
  require 'coveralls'

  SimpleCov.formatters = [SimpleCov::Formatter::HTMLFormatter, Coveralls::SimpleCov::Formatter]

  SimpleCov.start do
    add_filter '/spec'
    percent = jruby? ? 91.29 : 91.96
    minimum_coverage(percent)
  end
end

require 'multi_xml'
require 'rspec'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
