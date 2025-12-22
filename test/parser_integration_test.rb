require "test_helper"
require "parser_tests"

# Generate test classes for each parser
{
  "LibXML" => %w[libxml LibXML],
  "libxml_sax" => %w[libxml LibxmlSax],
  "REXML" => ["rexml/document", "REXML"],
  "Nokogiri" => %w[nokogiri Nokogiri],
  "nokogiri_sax" => %w[nokogiri NokogiriSax],
  "Ox" => %w[ox Ox],
  "Oga" => %w[oga Oga]
}.each do |parser_name, (require_name, class_name)|
  # Suppress parse-time warnings from oga gem
  if require_name == "oga"
    original_verbose = $VERBOSE
    $VERBOSE = nil
  end
  require require_name
  $VERBOSE = original_verbose if require_name == "oga"

  klass = Class.new(Minitest::Test) do
    include ParserTests

    const_set(:PARSER, parser_name)
  end

  Object.const_set("#{class_name}ParserTest", klass)
rescue LoadError
  puts "Tests not run for #{parser_name} due to a LoadError"
end
