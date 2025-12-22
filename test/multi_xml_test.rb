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

  def test_float_type_returns_float
    MultiXml.parser = :ox
    result = MultiXml.parse('<tag type="float">3.14</tag>')["tag"]

    assert_kind_of Float, result
    assert_in_delta(3.14, result)
  end

  def test_string_type_with_content_returns_string
    MultiXml.parser = :ox
    result = MultiXml.parse('<tag type="string">hello</tag>')["tag"]

    assert_kind_of String, result
    assert_equal "hello", result
  end

  def test_binary_type_with_base64_encoding_decodes_content
    MultiXml.parser = :ox
    result = MultiXml.parse('<tag type="binary" encoding="base64">ZGF0YQ==</tag>')["tag"]

    assert_equal "data", result
  end

  def test_binary_type_without_encoding_returns_raw_content
    MultiXml.parser = :ox
    result = MultiXml.parse('<tag type="binary">raw data</tag>')["tag"]

    assert_equal "raw data", result
  end

  def test_datetime_fallback_to_datetime_class
    MultiXml.parser = :ox
    # Use a datetime format that Time.parse might struggle with but DateTime handles
    result = MultiXml.parse('<tag type="datetime">1970-01-01T00:00:00+00:00</tag>')["tag"]

    assert_kind_of Time, result
  end

  def test_invalid_yaml_returns_original_string
    MultiXml.parser = :ox
    # Malformed YAML that triggers Psych::SyntaxError
    xml = '<tag type="yaml">{ invalid yaml content</tag>'
    result = MultiXml.parse(xml, disallowed_types: [])["tag"]

    assert_equal "{ invalid yaml content", result
  end

  def test_three_sibling_elements_creates_array
    MultiXml.parser = :ox
    # This triggers the Array branch in SAX parser add_value methods
    xml = "<users><user>A</user><user>B</user><user>C</user></users>"
    result = MultiXml.parse(xml)["users"]["user"]

    assert_kind_of Array, result
    assert_equal %w[A B C], result
  end
end

class ParserDetectionTest < Minitest::Test
  def setup
    # Save the current parser state
    @original_parser = MultiXml.instance_variable_get(:@parser)
  end

  def teardown
    # Restore the original parser state
    if @original_parser
      MultiXml.instance_variable_set(:@parser, @original_parser)
    elsif MultiXml.instance_variable_defined?(:@parser)
      MultiXml.send(:remove_instance_variable, :@parser)
    end
  end

  def test_find_loaded_parser_returns_libxml_when_ox_not_defined
    # Temporarily hide Ox constant
    ox_const = Object.send(:remove_const, :Ox)
    MultiXml.send(:remove_instance_variable, :@parser) if MultiXml.instance_variable_defined?(:@parser)

    result = MultiXml.send(:find_loaded_parser)

    assert_equal :libxml, result
  ensure
    Object.const_set(:Ox, ox_const)
  end

  def test_find_loaded_parser_returns_nokogiri_when_ox_and_libxml_not_defined
    ox_const = Object.send(:remove_const, :Ox)
    libxml_const = LibXML
    Object.send(:remove_const, :LibXML)

    result = MultiXml.send(:find_loaded_parser)

    assert_equal :nokogiri, result
  ensure
    Object.const_set(:Ox, ox_const)
    Object.const_set(:LibXML, libxml_const)
  end

  def test_find_loaded_parser_returns_oga_when_only_oga_defined
    ox_const = Object.send(:remove_const, :Ox)
    libxml_const = LibXML
    Object.send(:remove_const, :LibXML)
    nokogiri_const = Nokogiri
    Object.send(:remove_const, :Nokogiri)

    result = MultiXml.send(:find_loaded_parser)

    assert_equal :oga, result
  ensure
    Object.const_set(:Ox, ox_const)
    Object.const_set(:LibXML, libxml_const)
    Object.const_set(:Nokogiri, nokogiri_const)
  end

  def test_find_loaded_parser_returns_nil_when_no_parsers_defined
    ox_const = Object.send(:remove_const, :Ox)
    libxml_const = LibXML
    Object.send(:remove_const, :LibXML)
    nokogiri_const = Nokogiri
    Object.send(:remove_const, :Nokogiri)
    oga_const = Oga
    Object.send(:remove_const, :Oga)

    result = MultiXml.send(:find_loaded_parser)

    assert_nil result
  ensure
    Object.const_set(:Ox, ox_const)
    Object.const_set(:LibXML, libxml_const)
    Object.const_set(:Nokogiri, nokogiri_const)
    Object.const_set(:Oga, oga_const)
  end

  def test_find_available_parser_tries_to_load_parsers
    # This test verifies find_available_parser works by testing
    # that it successfully returns a parser when called
    result = MultiXml.send(:find_available_parser)

    assert_equal :ox, result
  end

  def test_find_available_parser_returns_nil_when_no_parsers_available
    # Mock PARSER_PREFERENCE to use non-existent libraries
    original_preference = MultiXml::PARSER_PREFERENCE
    MultiXml.send(:remove_const, :PARSER_PREFERENCE)
    MultiXml.const_set(:PARSER_PREFERENCE, [
      ["nonexistent_parser_1", :fake1],
      ["nonexistent_parser_2", :fake2]
    ])

    result = MultiXml.send(:find_available_parser)

    assert_nil result
  ensure
    MultiXml.send(:remove_const, :PARSER_PREFERENCE)
    MultiXml.const_set(:PARSER_PREFERENCE, original_preference)
  end

  def test_raise_no_parser_error_raises_no_parser_error
    error = assert_raises(MultiXml::NoParserError) do
      MultiXml.send(:raise_no_parser_error)
    end

    assert_match(/No XML parser detected/, error.message)
    assert_match(/ox/, error.message)
  end
end

class DateTimeFallbackTest < Minitest::Test
  def test_parse_datetime_falls_back_to_datetime_for_iso_week_format
    # ISO week format (e.g., "2020-W01") raises ArgumentError in Time.parse
    # but is handled by DateTime.parse, triggering the rescue branch
    converter = MultiXml::PARSE_DATETIME

    result = converter.call("2020-W01")

    assert_kind_of Time, result
    assert_equal Time.utc(2019, 12, 30), result
  end
end

class RexmlArrayBranchTest < Minitest::Test
  def test_add_to_hash_wraps_array_value_in_array
    # Test the elsif value.is_a?(Array) branch in REXML parser
    # This happens when a new key's value is already an array
    require "multi_xml/parsers/rexml"

    hash = {}
    value = %w[item1 item2]

    result = MultiXml::Parsers::Rexml.send(:add_to_hash, hash, "key", value)

    assert_equal [%w[item1 item2]], result["key"]
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
