require "test_helper"
require "mutant/minitest/coverage"
require "support/mock_decoder"

# Tests for MultiXml parser configuration
class MultiXmlParserConfigTest < Minitest::Test
  cover "MultiXml*"

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
end

# Tests for per-parse parser option
class MultiXmlPerParseParserTest < Minitest::Test
  cover "MultiXml*"

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

  def test_options_parser_key_is_truthy_when_present
    result = MultiXml.parse("<root>test</root>", parser: :nokogiri)

    assert_equal({"root" => "test"}, result)
  end

  def test_options_without_parser_uses_default
    MultiXml.parser = :rexml
    result = MultiXml.parse("<root>test</root>")

    assert_equal({"root" => "test"}, result)
  end
end

# Tests for XML type casting
class MultiXmlTypecastTest < Minitest::Test
  cover "MultiXml*"

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
    result = MultiXml.parse('<tag type="datetime">1970-01-01T00:00:00+00:00</tag>')["tag"]

    assert_kind_of Time, result
  end

  def test_invalid_yaml_returns_original_string
    MultiXml.parser = :ox
    xml = '<tag type="yaml">{ invalid yaml content</tag>'
    result = MultiXml.parse(xml, disallowed_types: [])["tag"]

    assert_equal "{ invalid yaml content", result
  end

  def test_three_sibling_elements_creates_array
    MultiXml.parser = :ox
    xml = "<users><user>A</user><user>B</user><user>C</user></users>"
    result = MultiXml.parse(xml)["users"]["user"]

    assert_kind_of Array, result
    assert_equal %w[A B C], result
  end
end

# Tests for empty input handling
class MultiXmlEmptyInputTest < Minitest::Test
  cover "MultiXml*"

  def test_parse_empty_string_returns_empty_hash
    result = MultiXml.parse("")

    assert_empty(result)
  end

  def test_parse_empty_xml_returns_empty_hash_not_nil
    result = MultiXml.parse("   ")

    assert_empty(result)
    refute_nil result
  end

  def test_parse_empty_input_early_returns
    result = MultiXml.parse("")

    assert_empty(result)
  end
end

# Tests for key transformation
class MultiXmlKeyTransformTest < Minitest::Test
  cover "MultiXml*"

  def test_parse_with_error_handling_undasherizes_keys
    result = MultiXml.parse("<root><my-key>value</my-key></root>")

    assert_equal({"root" => {"my_key" => "value"}}, result)
    refute result["root"].key?("my-key")
    assert result["root"].key?("my_key")
  end
end

# Tests for parse error handling
class MultiXmlParseErrorTest < Minitest::Test
  cover "MultiXml*"

  def test_parse_error_message_is_string
    MultiXml.parser = :nokogiri
    error = assert_raises(MultiXml::ParseError) do
      MultiXml.parse("<open></close>")
    end

    assert_kind_of String, error.message
    refute_match(/REXML::ParseException/, error.message) if error.message.is_a?(String)
  end
end

# Tests for parser loading
class MultiXmlParserLoadingTest < Minitest::Test
  cover "MultiXml*"

  def test_load_parser_with_mixed_case_name
    parser = MultiXml.send(:load_parser, "Nokogiri")

    assert_equal "MultiXml::Parsers::Nokogiri", parser.name
  end

  def test_load_parser_with_symbol
    parser = MultiXml.send(:load_parser, :NOKOGIRI)

    assert_equal "MultiXml::Parsers::Nokogiri", parser.name
  end

  def test_find_loaded_parser_uses_object_const_defined
    result = MultiXml.send(:find_loaded_parser)

    assert_find_loaded_parser_result(result)
  end

  def test_resolve_parser_with_class
    require "multi_xml/parsers/nokogiri"
    parser = MultiXml.send(:resolve_parser, MultiXml::Parsers::Nokogiri)

    assert_equal MultiXml::Parsers::Nokogiri, parser
  end

  private

  def assert_find_loaded_parser_result(result)
    expected = expected_loaded_parser
    expected ? assert_equal(expected, result) : assert_nil(result)
  end

  def expected_loaded_parser
    return :ox if defined?(Ox)
    return :libxml if defined?(LibXML)
    return :nokogiri if defined?(Nokogiri)

    :oga if defined?(Oga)
  end
end
