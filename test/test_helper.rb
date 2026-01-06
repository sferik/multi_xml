def jruby?
  RUBY_PLATFORM == "java"
end

def windows?
  Gem.win_platform?
end

# Returns the best available parser for the current platform
# ox and libxml are not available on Windows or JRuby
def best_available_parser
  if windows? || jruby?
    :nokogiri
  else
    :ox
  end
end

# Returns an array of parser constants that are actually loaded
def loaded_parser_consts
  %i[Ox LibXML Nokogiri Oga].select { |name| Object.const_defined?(name) }
end

require "simplecov"

SimpleCov.start do
  add_filter "/test"
  enable_coverage :branch
  minimum_coverage line: 100, branch: 100 unless ENV["MUTANT"]
end

require "multi_xml"
require "minitest/autorun"
require "minitest/mock"
require "mutant/minitest/coverage"
