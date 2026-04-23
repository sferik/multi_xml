require "test_helper"
require "parser_tests"

# Parser configurations: [require_name, class_name, test_module]
DOM_PARSERS = {
  "LibXML" => ["libxml-ruby", "LibXML", DomParserTests],
  "REXML" => ["rexml/document", "REXML", DomParserTests],
  "Nokogiri" => ["nokogiri", "Nokogiri", DomParserTests],
  "Ox" => ["ox", "Ox", DomParserTests],
  "Oga" => ["oga", "Oga", LenientDomParserTests]
}.freeze

SAX_PARSERS = {
  "libxml_sax" => ["libxml-ruby", "LibxmlSax", SaxParserFullTests],
  "nokogiri_sax" => ["nokogiri", "NokogiriSax", SaxParserFullTests]
}.freeze

# Generate test classes for each parser
DOM_PARSERS.merge(SAX_PARSERS).each do |parser_name, (require_name, class_name, test_module)|
  # Ox loads on TruffleRuby but its SAX callbacks miscompile, so the
  # produced hash is empty and every typecast/disallowed-type assertion
  # collapses. Skip the integration class entirely there; explicit
  # ``MultiXML.parser = :ox`` on a runtime where Ox actually works
  # still goes through the normal code path.
  next if parser_name == "Ox" && truffleruby?

  # Suppress parse-time warnings from oga gem
  if require_name == "oga"
    original_verbose = $VERBOSE
    $VERBOSE = nil
  end
  require require_name
  $VERBOSE = original_verbose if require_name == "oga"

  klass = Class.new(Minitest::Test) do
    include test_module

    const_set(:PARSER, parser_name)
  end

  Object.const_set("#{class_name}ParserTest", klass)
rescue LoadError
  puts "Tests not run for #{parser_name} due to a LoadError"
end
