require "test_helper"

# Tests for ParseOptionsTest
class ParseOptionsTest < Minitest::Test
  cover "MultiXml*"

  def setup
    @original_parser = MultiXml.instance_variable_get(:@parser)
    MultiXml.parser = best_available_parser
  end

  def teardown
    return unless @original_parser

    MultiXml.instance_variable_set(:@parser, @original_parser)
  end

  def test_parse_with_typecast_xml_value_true
    result = MultiXml.parse('<tag type="integer">42</tag>', typecast_xml_value: true)

    assert_equal 42, result["tag"]
  end

  def test_parse_with_typecast_xml_value_false
    result = MultiXml.parse('<tag type="integer">42</tag>', typecast_xml_value: false)

    assert_equal({"type" => "integer", "__content__" => "42"}, result["tag"])
  end

  def test_parse_with_symbolize_keys_true
    result = MultiXml.parse("<root><name>John</name></root>", symbolize_keys: true)

    assert_equal({root: {name: "John"}}, result)
  end

  def test_parse_with_symbolize_keys_false
    result = MultiXml.parse("<root><name>John</name></root>", symbolize_keys: false)

    assert_equal({"root" => {"name" => "John"}}, result)
  end

  def test_parse_with_disallowed_types_empty_allows_yaml
    result = MultiXml.parse('<tag type="yaml">--- test</tag>', disallowed_types: [])

    assert_equal "test", result["tag"]
  end

  def test_parse_with_custom_disallowed_types
    assert_raises(MultiXml::DisallowedTypeError) do
      MultiXml.parse('<tag type="integer">42</tag>', disallowed_types: ["integer"])
    end
  end

  def test_parse_uses_parser_option_when_provided
    MultiXml.parser = :rexml
    result = MultiXml.parse("<root>test</root>", parser: :nokogiri)

    assert_equal({"root" => "test"}, result)
  end

  def test_parse_uses_class_parser_when_parser_option_nil
    MultiXml.parser = best_available_parser
    # When options[:parser] is nil (falsy), should use class-level parser
    result = MultiXml.parse("<root>test</root>", parser: nil)

    assert_equal({"root" => "test"}, result)
  end
end

# Tests for ParseWithParserOptionTest
class ParseWithParserOptionTest < Minitest::Test
  cover "MultiXml*"

  def setup
    @original_parser = MultiXml.instance_variable_get(:@parser)
    MultiXml.parser = :rexml
  end

  def teardown
    return unless @original_parser

    MultiXml.instance_variable_set(:@parser, @original_parser)
  end

  def test_parse_uses_parser_option_when_truthy
    result = MultiXml.parse("<root>test</root>", parser: :nokogiri)

    assert_equal({"root" => "test"}, result)
  end

  def test_parse_uses_class_parser_when_parser_option_nil
    result = MultiXml.parse("<root>test</root>", parser: nil)

    # Should use REXML (the class parser we set)
    assert_equal({"root" => "test"}, result)
  end

  def test_parse_uses_class_parser_when_parser_option_false
    result = MultiXml.parse("<root>test</root>", parser: false)

    # Should use REXML (the class parser we set)
    assert_equal({"root" => "test"}, result)
  end

  def test_parse_with_explicit_parser_option
    MultiXml.parser = :rexml
    result = MultiXml.parse("<root>value</root>", parser: :nokogiri)

    # Should use Nokogiri, not REXML
    assert_equal({"root" => "value"}, result)
  end
end

# Tests parse option access behavior
class ParseOptionsAccessTest < Minitest::Test
  cover "MultiXml*"

  def setup
    @original_parser = MultiXml.instance_variable_get(:@parser)
  end

  def teardown
    return unless @original_parser

    MultiXml.instance_variable_set(:@parser, @original_parser)
  end

  def test_parse_accesses_parser_option_with_bracket
    # With fetch, missing key raises, with [] returns nil
    MultiXml.parser = best_available_parser

    # options without :parser key should work (use class-level parser)
    result = MultiXml.parse("<test>value</test>", symbolize_keys: false)

    assert_equal({"test" => "value"}, result)
  end

  def test_parse_uses_truthy_check_for_parser_option
    MultiXml.parser = :rexml

    # nil parser option should fall back to class parser
    result = MultiXml.parse("<r>v</r>", parser: nil)

    assert_equal({"r" => "v"}, result)
  end

  def test_parse_uses_provided_parser_when_truthy
    MultiXml.parser = :rexml

    # Truthy parser option should be used
    result = MultiXml.parse("<r>v</r>", parser: :nokogiri)

    assert_equal({"r" => "v"}, result)
  end

  def test_parse_accesses_typecast_option_correctly
    MultiXml.parser = best_available_parser

    result_with = MultiXml.parse('<n type="integer">42</n>', typecast_xml_value: true)
    result_without = MultiXml.parse('<n type="integer">42</n>', typecast_xml_value: false)

    assert_equal 42, result_with["n"]
    assert_equal({"type" => "integer", "__content__" => "42"}, result_without["n"])
  end

  def test_parse_accesses_symbolize_keys_option_correctly
    MultiXml.parser = best_available_parser

    result_with = MultiXml.parse("<root><name>v</name></root>", symbolize_keys: true)
    result_without = MultiXml.parse("<root><name>v</name></root>", symbolize_keys: false)

    assert_equal({root: {name: "v"}}, result_with)
    assert_equal({"root" => {"name" => "v"}}, result_without)
  end

  def test_parse_accesses_disallowed_types_option_correctly
    MultiXml.parser = best_available_parser

    assert_raises(MultiXml::DisallowedTypeError) do
      MultiXml.parse('<n type="yaml">test</n>', disallowed_types: ["yaml"])
    end
  end
end
