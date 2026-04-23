require "test_helper"
require "support/mock_decoder"

# Tests setting and retrieving the global XML parser backend
class MultiXmlParserConfigTest < Minitest::Test
  cover "MultiXML*"

  def setup
    @original_parser = MultiXML.instance_variable_get(:@parser)
  end

  def teardown
    if @original_parser
      MultiXML.instance_variable_set(:@parser, @original_parser)
    elsif MultiXML.instance_variable_defined?(:@parser)
      MultiXML.send(:remove_instance_variable, :@parser)
    end
  end

  def test_picks_a_default_parser
    parser = MultiXML.parser

    assert_kind_of Module, parser
    assert_respond_to parser, :parse
  end

  def test_defaults_to_the_best_available_gem
    MultiXML.send(:remove_instance_variable, :@parser) if MultiXML.instance_variable_defined?(:@parser)
    expected = (windows? || jruby?) ? "MultiXML::Parsers::Nokogiri" : "MultiXML::Parsers::Ox"

    assert_equal expected, MultiXML.parser.name
  end

  def test_is_settable_via_a_symbol
    MultiXML.parser = :rexml

    assert_equal "MultiXML::Parsers::Rexml", MultiXML.parser.name
  end

  def test_is_settable_via_a_class
    MultiXML.parser = MockDecoder

    assert_equal "MockDecoder", MultiXML.parser.name
  end
end

# Tests overriding the parser on a per-call basis via the :parser option
class MultiXmlPerParseParserTest < Minitest::Test
  cover "MultiXML*"

  def setup
    @original_parser = MultiXML.instance_variable_get(:@parser)
  end

  def teardown
    if @original_parser
      MultiXML.instance_variable_set(:@parser, @original_parser)
    elsif MultiXML.instance_variable_defined?(:@parser)
      MultiXML.send(:remove_instance_variable, :@parser)
    end
  end

  def test_allows_per_parse_parser_via_symbol
    MultiXML.parser = :rexml

    assert_equal({"user" => "Erik"}, MultiXML.parse("<user>Erik</user>", parser: :nokogiri))
  end

  def test_allows_per_parse_parser_via_string
    MultiXML.parser = :rexml

    assert_equal({"user" => "Erik"}, MultiXML.parse("<user>Erik</user>", parser: "nokogiri"))
  end

  def test_allows_per_parse_parser_via_class
    MultiXML.parser = :rexml
    require "multi_xml/parsers/nokogiri"

    assert_equal({"user" => "Erik"}, MultiXML.parse("<user>Erik</user>", parser: MultiXML::Parsers::Nokogiri))
  end

  def test_does_not_change_class_level_parser_when_using_per_parse_parser
    MultiXML.parser = :rexml
    MultiXML.parse("<user>Erik</user>", parser: :nokogiri)

    assert_equal "MultiXML::Parsers::Rexml", MultiXML.parser.name
  end

  def test_uses_class_level_parser_when_parser_option_is_not_provided
    MultiXML.parser = :nokogiri
    result = MultiXML.parse("<user>Erik</user>")

    assert_equal({"user" => "Erik"}, result)
  end

  def test_raises_error_for_invalid_per_parse_parser
    error = assert_raises(MultiXML::ParserLoadError) { MultiXML.parse("<user/>", parser: 123) }
    assert_match(/expected parser to be a Symbol, String, or Module/, error.message)
  end

  def test_wraps_parser_errors_correctly_with_per_parse_parser
    assert_raises(MultiXML::ParseError) { MultiXML.parse("<open></close>", parser: :nokogiri) }
  end

  def test_options_parser_key_is_truthy_when_present
    result = MultiXML.parse("<root>test</root>", parser: :nokogiri)

    assert_equal({"root" => "test"}, result)
  end

  def test_options_without_parser_uses_default
    MultiXML.parser = :rexml
    result = MultiXML.parse("<root>test</root>")

    assert_equal({"root" => "test"}, result)
  end
end

# Tests automatic type conversion based on XML type attributes (float, binary, datetime, etc.)
class MultiXmlTypecastTest < Minitest::Test
  cover "MultiXML*"

  def setup
    @original_parser = MultiXML.instance_variable_get(:@parser)
  end

  def teardown
    if @original_parser
      MultiXML.instance_variable_set(:@parser, @original_parser)
    elsif MultiXML.instance_variable_defined?(:@parser)
      MultiXML.send(:remove_instance_variable, :@parser)
    end
  end

  def test_float_type_returns_float
    MultiXML.parser = best_available_parser
    result = MultiXML.parse('<tag type="float">3.14</tag>')["tag"]

    assert_kind_of Float, result
    assert_in_delta(3.14, result)
  end

  def test_string_type_with_content_returns_string
    MultiXML.parser = best_available_parser
    result = MultiXML.parse('<tag type="string">hello</tag>')["tag"]

    assert_kind_of String, result
    assert_equal "hello", result
  end

  def test_binary_type_with_base64_encoding_decodes_content
    MultiXML.parser = best_available_parser
    result = MultiXML.parse('<tag type="binary" encoding="base64">ZGF0YQ==</tag>')["tag"]

    assert_equal "data", result
  end

  def test_binary_type_without_encoding_returns_raw_content
    MultiXML.parser = best_available_parser
    result = MultiXML.parse('<tag type="binary">raw data</tag>')["tag"]

    assert_equal "raw data", result
  end

  def test_datetime_fallback_to_datetime_class
    MultiXML.parser = best_available_parser
    result = MultiXML.parse('<tag type="datetime">1970-01-01T00:00:00+00:00</tag>')["tag"]

    assert_kind_of Time, result
  end

  def test_invalid_yaml_returns_original_string
    MultiXML.parser = best_available_parser
    xml = '<tag type="yaml">{ invalid yaml content</tag>'
    result = MultiXML.parse(xml, disallowed_types: [])["tag"]

    assert_equal "{ invalid yaml content", result
  end

  def test_three_sibling_elements_creates_array
    MultiXML.parser = best_available_parser
    xml = "<users><user>A</user><user>B</user><user>C</user></users>"
    result = MultiXML.parse(xml)["users"]["user"]

    assert_kind_of Array, result
    assert_equal %w[A B C], result
  end
end

# Tests for empty input handling
class MultiXmlEmptyInputTest < Minitest::Test
  cover "MultiXML*"

  def test_parse_empty_string_returns_empty_hash
    result = MultiXML.parse("")

    assert_empty(result)
  end

  def test_parse_empty_xml_returns_empty_hash_not_nil
    result = MultiXML.parse("   ")

    assert_empty(result)
    refute_nil result
  end

  def test_parse_empty_input_early_returns
    result = MultiXML.parse("")

    assert_empty(result)
  end
end

# Tests conversion of dashed XML element names to underscored Ruby hash keys
class MultiXmlKeyTransformTest < Minitest::Test
  cover "MultiXML*"

  def setup
    @original_parser = MultiXML.instance_variable_get(:@parser)
    MultiXML.parser = best_available_parser
  end

  def teardown
    if @original_parser
      MultiXML.instance_variable_set(:@parser, @original_parser)
    elsif MultiXML.instance_variable_defined?(:@parser)
      MultiXML.send(:remove_instance_variable, :@parser)
    end
  end

  def test_parse_with_error_handling_undasherizes_keys
    result = MultiXML.parse("<root><my-key>value</my-key></root>")

    assert_equal({"root" => {"my_key" => "value"}}, result)
    refute result["root"].key?("my-key")
    assert result["root"].key?("my_key")
  end
end

# Tests that malformed XML raises ParseError with a meaningful message
class MultiXmlParseErrorTest < Minitest::Test
  cover "MultiXML*"

  def setup
    @original_parser = MultiXML.instance_variable_get(:@parser)
  end

  def teardown
    if @original_parser
      MultiXML.instance_variable_set(:@parser, @original_parser)
    elsif MultiXML.instance_variable_defined?(:@parser)
      MultiXML.send(:remove_instance_variable, :@parser)
    end
  end

  def test_parse_error_message_is_string
    MultiXML.parser = :nokogiri
    error = assert_raises(MultiXML::ParseError) do
      MultiXML.parse("<open></close>")
    end

    assert_kind_of String, error.message
    refute_match(/REXML::ParseException/, error.message) if error.message.is_a?(String)
  end
end

# Tests for parser loading
class MultiXmlParserLoadingTest < Minitest::Test
  cover "MultiXML*"

  def test_load_parser_with_mixed_case_name
    parser = MultiXML.send(:load_parser, "Nokogiri")

    assert_equal "MultiXML::Parsers::Nokogiri", parser.name
  end

  def test_load_parser_with_symbol
    parser = MultiXML.send(:load_parser, :NOKOGIRI)

    assert_equal "MultiXML::Parsers::Nokogiri", parser.name
  end

  def test_find_loaded_parser_uses_object_const_defined
    result = MultiXML.send(:find_loaded_parser)

    assert_find_loaded_parser_result(result)
  end

  def test_resolve_parser_with_class
    require "multi_xml/parsers/nokogiri"
    parser = MultiXML.send(:resolve_parser, MultiXML::Parsers::Nokogiri)

    assert_equal MultiXML::Parsers::Nokogiri, parser
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
