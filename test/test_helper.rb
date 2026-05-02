def jruby?
  RUBY_PLATFORM == "java"
end

def truffleruby?
  RUBY_ENGINE == "truffleruby"
end

def windows?
  Gem.win_platform?
end

# Returns the parser MultiXML auto-detects on the current platform
# Used by tests that need to know "which backend will MultiXML pick by
# default", so the assertion stays correct as parser availability shifts
# across MRI / JRuby / TruffleRuby / Windows. Mirrors the
# {.find_loaded_parser} / {.find_available_parser} fallback that
# {.detect_parser} uses, so tests asserting against detect_parser still
# kill mutations that drop the loaded-parser branch.
def best_available_parser
  MultiXML.send(:find_loaded_parser) || MultiXML.send(:find_available_parser)
end

# Returns an array of parser constants that are actually loaded
def loaded_parser_consts
  %i[Ox LibXML Nokogiri Oga].select { |name| Object.const_defined?(name) }
end

require "simplecov"

SimpleCov.start do
  add_filter "/test"
  add_filter "/benchmark"
  add_filter "/benchmark.rb"
  # libxml-ruby and ox are :ruby-only gems, so their parser files are
  # unreachable on Windows / JRuby and would drag coverage below 100%.
  if windows? || jruby?
    add_filter "lib/multi_xml/parsers/libxml.rb"
    add_filter "lib/multi_xml/parsers/libxml_sax.rb"
    add_filter "lib/multi_xml/parsers/ox.rb"
  end
  # Ox tests are skipped on TruffleRuby — see
  # https://github.com/truffleruby/truffleruby/issues/4236 — because Minitest
  # stubs elsewhere in the suite cause TruffleRuby's JIT to drop SAX
  # attribute callbacks. Filter the parser file out of coverage to match
  # the skip; the uncovered lines reflect the platform workaround, not
  # a real test gap.
  add_filter "lib/multi_xml/parsers/ox.rb" if truffleruby?
  enable_coverage :branch unless jruby? || truffleruby?
  unless ENV["MUTANT"]
    if truffleruby?
      # TruffleRuby's coverage tracker doesn't credit case/when headers
      # or Fiber[]= writes as covered, so the line threshold is relaxed
      # below 100% to match its own bookkeeping quirks rather than a
      # real test gap.
      minimum_coverage(line: 97)
    elsif jruby?
      minimum_coverage(line: 100)
    else
      minimum_coverage(line: 100, branch: 100)
    end
  end
end

require "multi_xml"
require "minitest/autorun"
require "minitest/mock"
require "mutant/minitest/coverage"
