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
  # libxml-ruby and ox are :ruby-only gems, so their parser files are
  # unreachable on Windows / JRuby and would drag coverage below 100%.
  if windows? || jruby?
    add_filter "lib/multi_xml/parsers/libxml.rb"
    add_filter "lib/multi_xml/parsers/libxml_sax.rb"
    add_filter "lib/multi_xml/parsers/ox.rb"
  end
  enable_coverage :branch unless jruby?
  unless ENV["MUTANT"]
    jruby? ? minimum_coverage(line: 100) : minimum_coverage(line: 100, branch: 100)
  end
end

require "multi_xml"
require "minitest/autorun"
require "minitest/mock"
require "mutant/minitest/coverage"
