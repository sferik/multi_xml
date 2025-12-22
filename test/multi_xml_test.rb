require "test_helper"
require "parser_test_module"

class MockDecoder
  def self.parse
  end
end

class MultiXmlTest < Minitest::Test
  def test_picks_a_default_parser
    parser = MultiXml.parser

    assert_kind_of Module, parser
    assert_respond_to parser, :parse
  end

  def test_defaults_to_the_best_available_gem
    MultiXml.send(:remove_instance_variable, :@parser) if MultiXml.instance_variable_defined?(:@parser)
    expected = jruby? ? "MultiXml::Parsers::Nokogiri" : "MultiXml::Parsers::Ox"

    assert_equal expected, MultiXml.parser.name
  end

  def test_is_settable_via_a_symbol
    MultiXml.parser = :rexml

    assert_equal "MultiXml::Parsers::Rexml", MultiXml.parser.name
  end

  def test_is_settable_via_a_class
    MultiXml.parser = MockDecoder

    assert_equal "MockDecoder", MultiXml.parser.name
  end

  def test_allows_per_parse_parser_via_symbol
    MultiXml.parser = :rexml

    assert_equal({"user" => "Erik"}, MultiXml.parse("<user>Erik</user>", parser: :nokogiri))
  end

  def test_allows_per_parse_parser_via_string
    MultiXml.parser = :rexml

    assert_equal({"user" => "Erik"}, MultiXml.parse("<user>Erik</user>", parser: "nokogiri"))
  end

  def test_allows_per_parse_parser_via_class
    MultiXml.parser = :rexml
    require "multi_xml/parsers/nokogiri"

    assert_equal({"user" => "Erik"}, MultiXml.parse("<user>Erik</user>", parser: MultiXml::Parsers::Nokogiri))
  end

  def test_does_not_change_class_level_parser_when_using_per_parse_parser
    MultiXml.parser = :rexml
    MultiXml.parse("<user>Erik</user>", parser: :nokogiri)

    assert_equal "MultiXml::Parsers::Rexml", MultiXml.parser.name
  end

  def test_uses_class_level_parser_when_parser_option_is_not_provided
    MultiXml.parser = :nokogiri
    result = MultiXml.parse("<user>Erik</user>")

    assert_equal({"user" => "Erik"}, result)
  end

  def test_raises_error_for_invalid_per_parse_parser
    error = assert_raises(RuntimeError) { MultiXml.parse("<user/>", parser: 123) }
    assert_match(/Invalid parser specification/, error.message)
  end

  def test_wraps_parser_errors_correctly_with_per_parse_parser
    assert_raises(MultiXml::ParseError) { MultiXml.parse("<open></close>", parser: :nokogiri) }
  end
end

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
  require require_name

  klass = Class.new(Minitest::Test) do
    include ParserTests

    const_set(:PARSER, parser_name)
  end

  Object.const_set("#{class_name}ParserTest", klass)
rescue LoadError
  puts "Tests not run for #{parser_name} due to a LoadError"
end
