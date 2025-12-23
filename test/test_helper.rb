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
  minimum_coverage(100)
end

require "multi_xml"
require "minitest/autorun"
require "mutant/minitest/coverage"
