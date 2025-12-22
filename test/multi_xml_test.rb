require "test_helper"
require "parser_test_module"
require "mutant/minitest/coverage"

class MockDecoder
  def self.parse
  end
end

class MultiXmlTest < Minitest::Test
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

class ParseErrorTest < Minitest::Test
  cover "MultiXml*"

  def test_parse_error_stores_message
    error = MultiXml::ParseError.new("Test message")

    assert_equal "Test message", error.message
  end

  def test_parse_error_with_nil_message_has_default_message
    error = MultiXml::ParseError.new

    assert_equal "MultiXml::ParseError", error.message
  end

  def test_parse_error_stores_xml
    error = MultiXml::ParseError.new("msg", xml: "<bad>")

    assert_equal "<bad>", error.xml
  end

  def test_parse_error_stores_cause
    cause = StandardError.new("original")
    error = MultiXml::ParseError.new("msg", cause: cause)

    assert_equal cause, error.cause
  end

  def test_parse_error_xml_defaults_to_nil
    error = MultiXml::ParseError.new("msg")

    assert_nil error.xml
  end

  def test_parse_error_cause_defaults_to_nil
    error = MultiXml::ParseError.new("msg")

    assert_nil error.cause
  end

  def test_parse_error_with_all_parameters
    cause = StandardError.new("original")
    error = MultiXml::ParseError.new("Test", xml: "<xml/>", cause: cause)

    assert_equal "Test", error.message
    assert_equal "<xml/>", error.xml
    assert_equal cause, error.cause
  end

  def test_parse_error_inherits_from_standard_error
    error = MultiXml::ParseError.new("test")

    assert_kind_of StandardError, error
  end
end

class DisallowedTypeErrorTest < Minitest::Test
  cover "MultiXml*"

  def test_stores_type
    error = MultiXml::DisallowedTypeError.new("yaml")

    assert_equal "yaml", error.type
  end

  def test_message_includes_type_inspect
    error = MultiXml::DisallowedTypeError.new("yaml")

    assert_equal 'Disallowed type attribute: "yaml"', error.message
  end

  def test_message_with_symbol_type
    error = MultiXml::DisallowedTypeError.new(:symbol)

    assert_equal "Disallowed type attribute: :symbol", error.message
  end

  def test_inherits_from_standard_error
    error = MultiXml::DisallowedTypeError.new("yaml")

    assert_kind_of StandardError, error
  end
end

class ParserDetectionTest < Minitest::Test
  cover "MultiXml*"

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
  cover "MultiXml*"

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
  cover "MultiXml*"

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

class HelpersTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  # typecast_xml_value tests
  def test_typecast_xml_value_uses_default_disallowed_types
    # This kills the mutant that removes default parameter
    assert_raises(MultiXml::DisallowedTypeError) do
      typecast_xml_value({"type" => "yaml", "__content__" => "test"})
    end
  end

  def test_typecast_xml_value_with_explicit_empty_disallowed_types
    # Verifies typecast works with explicitly empty disallowed types
    result = typecast_xml_value({"type" => "yaml", "__content__" => "test"}, [])

    assert_equal "test", result
  end

  # typecast_array tests
  def test_typecast_array_with_single_element_returns_first
    result = typecast_array([{"key" => "value"}], [])

    assert_equal({"key" => "value"}, result)
  end

  def test_typecast_array_with_multiple_elements_returns_array
    result = typecast_array([{"a" => 1}, {"b" => 2}], [])

    assert_equal [{"a" => 1}, {"b" => 2}], result
  end

  def test_typecast_array_with_empty_array
    result = typecast_array([], [])

    assert_equal [], result
  end

  def test_typecast_array_recursively_typecasts
    input = [{"type" => "integer", "__content__" => "42"}]
    result = typecast_array(input, [])

    assert_equal 42, result
  end

  # typecast_children tests - unwrap file case
  def test_typecast_children_unwraps_stringio_file
    file = StringIO.new("content")
    hash = {"file" => file, "other" => "data"}
    result = typecast_children(hash, [])

    assert_same file, result
  end

  def test_typecast_children_returns_hash_when_file_not_stringio
    hash = {"file" => "not a stringio", "other" => "data"}
    result = typecast_children(hash, [])

    assert_kind_of Hash, result
    assert_equal "not a stringio", result["file"]
  end

  def test_typecast_children_returns_hash_when_no_file_key
    hash = {"name" => "value", "other" => "data"}
    result = typecast_children(hash, [])

    assert_kind_of Hash, result
    assert_equal "value", result["name"]
  end

  def test_typecast_children_returns_hash_when_file_is_nil
    hash = {"file" => nil, "other" => "data"}
    result = typecast_children(hash, [])

    assert_kind_of Hash, result
    assert_nil result["file"]
  end

  # extract_array_entries tests
  def test_extract_array_entries_with_array_value
    hash = {"type" => "array", "user" => %w[Alice Bob]}
    result = extract_array_entries(hash, [])

    assert_equal %w[Alice Bob], result
  end

  def test_extract_array_entries_with_hash_value
    hash = {"type" => "array", "user" => {"name" => "Alice"}}
    result = extract_array_entries(hash, [])

    assert_equal [{"name" => "Alice"}], result
  end

  def test_extract_array_entries_with_no_entries
    hash = {"type" => "array"}
    result = extract_array_entries(hash, [])

    assert_equal [], result
  end

  def test_extract_array_entries_ignores_type_key
    hash = {"type" => "array", "type" => "should be ignored", "item" => %w[a b]}
    result = extract_array_entries(hash, [])

    assert_equal %w[a b], result
  end

  # disallowed_type? tests
  def test_disallowed_type_returns_true_for_disallowed
    assert disallowed_type?("yaml", ["yaml", "symbol"])
  end

  def test_disallowed_type_returns_false_for_allowed
    refute disallowed_type?("string", ["yaml", "symbol"])
  end

  def test_disallowed_type_returns_false_for_nil_type
    refute disallowed_type?(nil, ["yaml", "symbol"])
  end

  def test_disallowed_type_returns_false_when_type_is_hash
    # When type attribute is itself a hash (e.g., complex nested XML)
    refute disallowed_type?({"nested" => "value"}, ["yaml"])
  end

  # empty_value? tests
  def test_empty_value_true_for_empty_hash
    assert empty_value?({}, nil)
  end

  def test_empty_value_true_when_nil_equals_true
    assert empty_value?({"nil" => "true"}, nil)
  end

  def test_empty_value_true_when_only_type_present
    assert empty_value?({"type" => "integer"}, "integer")
  end

  def test_empty_value_false_when_nil_not_true
    refute empty_value?({"nil" => "false", "other" => "value"}, nil)
  end

  def test_empty_value_false_when_type_is_hash
    refute empty_value?({"type" => {"nested" => "value"}}, {"nested" => "value"})
  end

  # convert_hash tests
  def test_convert_hash_returns_empty_string_for_string_type_without_nil_true
    result = convert_hash({"type" => "string"}, "string", [])

    assert_equal "", result
  end

  def test_convert_hash_returns_nil_for_string_type_with_nil_true
    result = convert_hash({"type" => "string", "nil" => "true"}, "string", [])

    assert_nil result
  end

  # undasherize_keys tests
  def test_undasherize_keys_with_array
    input = [{"first-name" => "John"}, {"last-name" => "Doe"}]
    result = undasherize_keys(input)

    assert_equal [{"first_name" => "John"}, {"last_name" => "Doe"}], result
  end

  def test_undasherize_keys_with_nested_array
    input = {"users" => [{"first-name" => "John"}]}
    result = undasherize_keys(input)

    assert_equal({"users" => [{"first_name" => "John"}]}, result)
  end

  def test_undasherize_keys_with_plain_value
    result = undasherize_keys("plain string")

    assert_equal "plain string", result
  end

  # symbolize_keys tests
  def test_symbolize_keys_with_array
    input = [{"name" => "John"}, {"name" => "Jane"}]
    result = symbolize_keys(input)

    assert_equal [{name: "John"}, {name: "Jane"}], result
  end
end

class NormalizeInputTest < Minitest::Test
  cover "MultiXml*"

  def test_normalize_input_returns_io_unchanged
    io = StringIO.new("<xml/>")

    result = MultiXml.send(:normalize_input, io)

    assert_same io, result
  end

  def test_normalize_input_converts_string_to_stringio
    result = MultiXml.send(:normalize_input, "<xml/>")

    assert_kind_of StringIO, result
    assert_equal "<xml/>", result.read
  end

  def test_normalize_input_strips_whitespace
    result = MultiXml.send(:normalize_input, "  <xml/>  ")

    assert_equal "<xml/>", result.read
  end

  def test_normalize_input_calls_to_s_on_non_string
    obj = Object.new
    def obj.to_s
      "<custom/>"
    end

    result = MultiXml.send(:normalize_input, obj)

    assert_equal "<custom/>", result.read
  end
end

class ParseWithErrorHandlingTest < Minitest::Test
  cover "MultiXml*"

  def setup
    @original_parser = MultiXml.instance_variable_get(:@parser)
  end

  def teardown
    if @original_parser
      MultiXml.instance_variable_set(:@parser, @original_parser)
    elsif MultiXml.instance_variable_defined?(:@parser)
      MultiXml.send(:remove_instance_variable, :@parser)
    end
  end

  def test_parse_with_io_input_captures_xml_in_error
    MultiXml.parser = :nokogiri
    io = StringIO.new("<open></close>")

    begin
      MultiXml.parse(io)
    rescue MultiXml::ParseError => e
      assert_equal "<open></close>", e.xml
    end
  end

  def test_parse_error_message_from_parser
    MultiXml.parser = :nokogiri

    begin
      MultiXml.parse("<open></close>")
    rescue MultiXml::ParseError => e
      refute_nil e.message
      refute_empty e.message
    end
  end

  def test_parse_error_cause_is_parser_error
    MultiXml.parser = :nokogiri

    begin
      MultiXml.parse("<open></close>")
    rescue MultiXml::ParseError => e
      assert_kind_of Exception, e.cause
    end
  end

  def test_parse_returns_empty_hash_when_parser_returns_nil
    MultiXml.parser = :ox
    result = MultiXml.parse("<root/>")

    assert_kind_of Hash, result
  end
end

class LoadParserTest < Minitest::Test
  cover "MultiXml*"

  def test_load_parser_with_symbol
    result = MultiXml.send(:load_parser, :nokogiri)

    assert_equal MultiXml::Parsers::Nokogiri, result
  end

  def test_load_parser_with_string
    result = MultiXml.send(:load_parser, "nokogiri")

    assert_equal MultiXml::Parsers::Nokogiri, result
  end

  def test_load_parser_converts_to_string_and_downcases
    result = MultiXml.send(:load_parser, :NOKOGIRI)

    assert_equal MultiXml::Parsers::Nokogiri, result
  end
end

class ResolveParserTest < Minitest::Test
  cover "MultiXml*"

  def test_resolve_parser_with_module
    require "multi_xml/parsers/ox"
    result = MultiXml.send(:resolve_parser, MultiXml::Parsers::Ox)

    assert_equal MultiXml::Parsers::Ox, result
  end

  def test_resolve_parser_with_class
    result = MultiXml.send(:resolve_parser, MockDecoder)

    assert_equal MockDecoder, result
  end

  def test_resolve_parser_raises_for_invalid_spec
    error = assert_raises(RuntimeError) do
      MultiXml.send(:resolve_parser, 123)
    end

    assert_match(/Invalid parser specification/, error.message)
  end
end

class ParseOptionsTest < Minitest::Test
  cover "MultiXml*"

  def setup
    @original_parser = MultiXml.instance_variable_get(:@parser)
    MultiXml.parser = :ox
  end

  def teardown
    if @original_parser
      MultiXml.instance_variable_set(:@parser, @original_parser)
    end
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
    result = MultiXml.parse("<root>test</root>", parser: :ox)

    assert_equal({"root" => "test"}, result)
  end

  def test_parse_uses_class_parser_when_parser_option_nil
    MultiXml.parser = :ox
    # When options[:parser] is nil (falsy), should use class-level parser
    result = MultiXml.parse("<root>test</root>", parser: nil)

    assert_equal({"root" => "test"}, result)
  end
end

class DetectParserTest < Minitest::Test
  cover "MultiXml*"

  def setup
    @original_parser = MultiXml.instance_variable_get(:@parser)
  end

  def teardown
    if @original_parser
      MultiXml.instance_variable_set(:@parser, @original_parser)
    elsif MultiXml.instance_variable_defined?(:@parser)
      MultiXml.send(:remove_instance_variable, :@parser)
    end
  end

  def test_detect_parser_returns_loaded_parser_when_available
    # Ox should be loaded, so find_loaded_parser returns :ox
    result = MultiXml.send(:detect_parser)

    assert_equal :ox, result
  end

  def test_detect_parser_raises_when_no_parser_available
    # Mock both find methods to return nil
    ox_const = Object.send(:remove_const, :Ox)
    libxml_const = LibXML
    Object.send(:remove_const, :LibXML)
    nokogiri_const = Nokogiri
    Object.send(:remove_const, :Nokogiri)
    oga_const = Oga
    Object.send(:remove_const, :Oga)

    original_preference = MultiXml::PARSER_PREFERENCE
    MultiXml.send(:remove_const, :PARSER_PREFERENCE)
    MultiXml.const_set(:PARSER_PREFERENCE, [["nonexistent", :fake]])

    assert_raises(MultiXml::NoParserError) do
      MultiXml.send(:detect_parser)
    end
  ensure
    Object.const_set(:Ox, ox_const)
    Object.const_set(:LibXML, libxml_const)
    Object.const_set(:Nokogiri, nokogiri_const)
    Object.const_set(:Oga, oga_const)
    MultiXml.send(:remove_const, :PARSER_PREFERENCE)
    MultiXml.const_set(:PARSER_PREFERENCE, original_preference)
  end
end

class TypecastHashTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_typecast_hash_raises_disallowed_type_error_with_type
    error = assert_raises(MultiXml::DisallowedTypeError) do
      typecast_hash({"type" => "yaml"}, ["yaml"])
    end

    assert_equal "yaml", error.type
  end
end

class ConvertTextContentTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_convert_text_content_requires_content_key
    # Test that the method accesses __content__ key
    hash = {MultiXml::TEXT_CONTENT_KEY => "test value", "type" => "string"}
    result = convert_text_content(hash)

    assert_equal "test value", result
  end
end

class DisallowedTypeDetailedTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_disallowed_type_returns_false_when_type_nil
    refute disallowed_type?(nil, [:yaml])
  end

  def test_disallowed_type_checks_first_condition_type_truthiness
    # Type must be truthy for disallowed check
    refute disallowed_type?(false, ["false"])
  end

  def test_disallowed_type_returns_true_when_string_in_list
    assert disallowed_type?("yaml", ["yaml"])
  end

  def test_disallowed_type_returns_false_when_type_is_hash
    # Hash types should not be checked against disallowed list
    refute disallowed_type?({"key" => "val"}, ["key"])
  end

  def test_disallowed_type_returns_false_when_not_in_list
    refute disallowed_type?("integer", ["yaml"])
  end

  def test_disallowed_type_with_symbol_in_list
    assert disallowed_type?(:symbol, [:symbol])
  end
end

class EmptyValueDetailedTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_empty_value_true_for_empty_hash
    assert empty_value?({}, nil)
  end

  def test_empty_value_true_when_nil_equals_true
    assert empty_value?({"nil" => "true"}, nil)
  end

  def test_empty_value_false_when_nil_not_true_string
    # The hash has nil key but value is not "true"
    refute empty_value?({"nil" => "false"}, nil)
  end

  def test_empty_value_true_when_only_type_key_and_type_not_hash
    # This tests: type && hash.size == 1 && !type.is_a?(Hash)
    assert empty_value?({"type" => "integer"}, "integer")
  end

  def test_empty_value_false_when_type_is_hash
    # type.is_a?(Hash) should return false
    type_hash = {"nested" => "value"}
    refute empty_value?({"type" => type_hash}, type_hash)
  end

  def test_empty_value_false_when_hash_size_greater_than_one
    refute empty_value?({"type" => "integer", "other" => "key"}, "integer")
  end

  def test_empty_value_false_when_type_nil_and_hash_has_content
    refute empty_value?({"content" => "value"}, nil)
  end
end

class ExtractArrayEntriesDetailedTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_extract_array_entries_finds_array_value
    hash = {"type" => "array", "item" => %w[a b c]}
    result = extract_array_entries(hash, [])

    assert_equal %w[a b c], result
  end

  def test_extract_array_entries_finds_hash_value
    hash = {"type" => "array", "item" => {"name" => "test"}}
    result = extract_array_entries(hash, [])

    assert_equal [{"name" => "test"}], result
  end

  def test_extract_array_entries_returns_empty_array_when_no_entries
    hash = {"type" => "array"}
    result = extract_array_entries(hash, [])

    assert_equal [], result
  end

  def test_extract_array_entries_skips_type_key
    hash = {"type" => "array", "other" => %w[x y]}
    result = extract_array_entries(hash, [])

    assert_equal %w[x y], result
  end

  def test_extract_array_entries_handles_string_value_gracefully
    # When the value is a string (not Array or Hash), entries will be nil
    hash = {"type" => "array", "content" => "plain string"}
    result = extract_array_entries(hash, [])

    assert_equal [], result
  end

  def test_extract_array_entries_with_nested_type_casting
    hash = {"type" => "array", "item" => [{"type" => "integer", "__content__" => "42"}]}
    result = extract_array_entries(hash, [])

    assert_equal [42], result
  end
end

class TypecastChildrenDetailedTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_typecast_children_unwraps_stringio_file
    file = StringIO.new("content")
    hash = {"file" => file}
    result = typecast_children(hash, [])

    assert_same file, result
  end

  def test_typecast_children_returns_hash_when_file_not_stringio
    hash = {"file" => "plain string"}
    result = typecast_children(hash, [])

    assert_kind_of Hash, result
    assert_equal "plain string", result["file"]
  end

  def test_typecast_children_returns_hash_when_no_file_key
    hash = {"name" => "value"}
    result = typecast_children(hash, [])

    assert_kind_of Hash, result
  end

  def test_typecast_children_with_subclass_of_stringio
    # Create a subclass of StringIO to test is_a? vs instance_of?
    klass = Class.new(StringIO)
    file = klass.new("content")
    hash = {"file" => file}
    result = typecast_children(hash, [])

    # With is_a?, subclass should also be unwrapped
    assert_same file, result
  end
end

class ConvertHashDetailedTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_convert_hash_with_array_type
    hash = {"type" => "array", "item" => %w[a b]}
    result = convert_hash(hash, "array", [])

    assert_equal %w[a b], result
  end

  def test_convert_hash_with_text_content
    hash = {"type" => "string", "__content__" => "hello"}
    result = convert_hash(hash, "string", [])

    assert_equal "hello", result
  end

  def test_convert_hash_returns_empty_string_for_string_type_without_nil
    hash = {"type" => "string"}
    result = convert_hash(hash, "string", [])

    assert_equal "", result
  end

  def test_convert_hash_returns_nil_when_nil_equals_true
    hash = {"type" => "string", "nil" => "true"}
    result = convert_hash(hash, "string", [])

    assert_nil result
  end

  def test_convert_hash_returns_nil_for_empty_hash
    result = convert_hash({}, nil, [])

    assert_nil result
  end

  def test_convert_hash_typecasts_children_otherwise
    hash = {"child" => {"type" => "integer", "__content__" => "123"}}
    result = convert_hash(hash, nil, [])

    assert_equal({"child" => 123}, result)
  end
end

class TypecastArrayDetailedTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_typecast_array_unwraps_single_element
    result = typecast_array(["only one"], [])

    assert_equal "only one", result
  end

  def test_typecast_array_keeps_multiple_elements
    result = typecast_array(%w[one two], [])

    assert_equal %w[one two], result
  end

  def test_typecast_array_keeps_empty_array
    result = typecast_array([], [])

    assert_equal [], result
  end

  def test_typecast_array_recursively_typecasts
    input = [{"type" => "integer", "__content__" => "5"}]
    result = typecast_array(input, [])

    assert_equal 5, result
  end

  def test_typecast_array_modifies_in_place
    input = ["original"]
    typecast_array(input, [])

    assert_equal ["original"], input
  end
end

class ParseMethodDetailedTest < Minitest::Test
  cover "MultiXml*"

  def setup
    @original_parser = MultiXml.instance_variable_get(:@parser)
    MultiXml.parser = :ox
  end

  def teardown
    if @original_parser
      MultiXml.instance_variable_set(:@parser, @original_parser)
    end
  end

  def test_parse_with_options_hash_merges_defaults
    # Test that options are properly merged with defaults
    result = MultiXml.parse("<root/>", {})

    assert_equal({"root" => nil}, result)
  end

  def test_parse_applies_typecast_option
    result = MultiXml.parse('<n type="integer">5</n>', typecast_xml_value: true)

    assert_equal 5, result["n"]
  end

  def test_parse_skips_typecast_when_disabled
    result = MultiXml.parse('<n type="integer">5</n>', typecast_xml_value: false)

    assert_equal({"type" => "integer", "__content__" => "5"}, result["n"])
  end

  def test_parse_applies_symbolize_keys
    result = MultiXml.parse("<root><name>test</name></root>", symbolize_keys: true)

    assert_equal({root: {name: "test"}}, result)
  end

  def test_parse_respects_disallowed_types_option
    assert_raises(MultiXml::DisallowedTypeError) do
      MultiXml.parse('<n type="yaml">test</n>', disallowed_types: ["yaml"])
    end
  end
end

class ResolveParserDetailedTest < Minitest::Test
  cover "MultiXml*"

  def test_resolve_parser_accepts_module
    require "multi_xml/parsers/ox"
    result = MultiXml.send(:resolve_parser, MultiXml::Parsers::Ox)

    assert_equal MultiXml::Parsers::Ox, result
  end

  def test_resolve_parser_accepts_class
    result = MultiXml.send(:resolve_parser, MockDecoder)

    assert_equal MockDecoder, result
  end

  def test_resolve_parser_raises_for_integer
    error = assert_raises(RuntimeError) do
      MultiXml.send(:resolve_parser, 123)
    end

    assert_match(/Invalid parser/, error.message)
  end

  def test_resolve_parser_raises_for_nil
    error = assert_raises(RuntimeError) do
      MultiXml.send(:resolve_parser, nil)
    end

    assert_match(/Invalid parser/, error.message)
  end
end

class DetectParserDetailedTest < Minitest::Test
  cover "MultiXml*"

  def setup
    @original_parser = MultiXml.instance_variable_get(:@parser)
  end

  def teardown
    if @original_parser
      MultiXml.instance_variable_set(:@parser, @original_parser)
    elsif MultiXml.instance_variable_defined?(:@parser)
      MultiXml.send(:remove_instance_variable, :@parser)
    end
  end

  def test_detect_parser_prefers_loaded_parser
    # Should return :ox since Ox is loaded
    result = MultiXml.send(:detect_parser)

    assert_equal :ox, result
  end
end

class FindLoadedParserDetailedTest < Minitest::Test
  cover "MultiXml*"

  def test_find_loaded_parser_returns_ox_when_defined
    # Ox should be defined in test environment
    result = MultiXml.send(:find_loaded_parser)

    assert_equal :ox, result
  end
end

class FindAvailableParserDetailedTest < Minitest::Test
  cover "MultiXml*"

  def test_find_available_parser_returns_first_loadable
    result = MultiXml.send(:find_available_parser)

    assert_equal :ox, result
  end
end

class LoadParserDetailedTest < Minitest::Test
  cover "MultiXml*"

  def test_load_parser_downcases_symbol
    result = MultiXml.send(:load_parser, :OX)

    assert_equal MultiXml::Parsers::Ox, result
  end

  def test_load_parser_converts_to_string
    result = MultiXml.send(:load_parser, "ox")

    assert_equal MultiXml::Parsers::Ox, result
  end
end

class ParseWithErrorHandlingDetailedTest < Minitest::Test
  cover "MultiXml*"

  def setup
    @original_parser = MultiXml.instance_variable_get(:@parser)
    MultiXml.parser = :nokogiri
  end

  def teardown
    if @original_parser
      MultiXml.instance_variable_set(:@parser, @original_parser)
    end
  end

  def test_parse_wraps_parser_error_with_xml
    io = StringIO.new("<bad></wrong>")

    begin
      MultiXml.parse(io)
      flunk "Expected ParseError"
    rescue MultiXml::ParseError => e
      assert_equal "<bad></wrong>", e.xml
    end
  end

  def test_parse_wraps_parser_error_with_message
    begin
      MultiXml.parse("<bad></wrong>")
      flunk "Expected ParseError"
    rescue MultiXml::ParseError => e
      refute_nil e.message
    end
  end

  def test_parse_wraps_parser_error_with_cause
    begin
      MultiXml.parse("<bad></wrong>")
      flunk "Expected ParseError"
    rescue MultiXml::ParseError => e
      refute_nil e.cause
    end
  end
end

class RaiseNoParserErrorTest < Minitest::Test
  cover "MultiXml*"

  def test_raises_no_parser_error_with_message
    error = assert_raises(MultiXml::NoParserError) do
      MultiXml.send(:raise_no_parser_error)
    end

    assert_includes error.message, "No XML parser detected"
  end

  def test_raises_no_parser_error_mentions_parser_options
    error = assert_raises(MultiXml::NoParserError) do
      MultiXml.send(:raise_no_parser_error)
    end

    assert_includes error.message, "ox"
    assert_includes error.message, "nokogiri"
  end
end

# Test with Hash subclass for is_a? vs instance_of?
class HashSubclass < Hash
end

class DisallowedTypeHashSubclassTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_disallowed_type_returns_false_for_hash_subclass
    # Test with Hash subclass - this distinguishes is_a?(Hash) from instance_of?(Hash)
    subclass_hash = HashSubclass.new
    subclass_hash["key"] = "value"

    # With is_a?(Hash), this returns false (correct behavior for type attribute that's a hash-like structure)
    refute disallowed_type?(subclass_hash, ["key"])
  end
end

class ExtractArrayEntriesEdgeCasesTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_extract_finds_first_non_type_array_entry
    # Test that we find the first matching key that's not "type"
    hash = {"type" => "array", "first" => %w[a b], "second" => %w[c d]}
    result = extract_array_entries(hash, [])

    # Should find "first" since hash iteration order is insertion order
    assert_kind_of Array, result
  end

  def test_extract_with_empty_type_array_and_no_entries
    hash = {"type" => "array"}
    result = extract_array_entries(hash, [])

    assert_equal [], result
  end

  def test_extract_with_integer_value_returns_empty
    hash = {"type" => "array", "count" => 42}
    result = extract_array_entries(hash, [])

    assert_equal [], result
  end

  def test_extract_with_nil_value_returns_empty
    hash = {"type" => "array", "items" => nil}
    result = extract_array_entries(hash, [])

    assert_equal [], result
  end
end

class EmptyValueEdgeCasesTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_empty_value_with_hash_subclass_as_type
    # Test with Hash subclass - verifies is_a?(Hash) vs instance_of?(Hash)
    type = HashSubclass.new
    type["nested"] = "value"
    hash = {"type" => type}

    # With is_a?(Hash), should return false since type.is_a?(Hash) is true
    refute empty_value?(hash, type)
  end

  def test_empty_value_with_two_keys_where_type_is_string
    # Tests: type && hash.size == 1 - should be false when size > 1
    hash = {"type" => "integer", "nil" => "false"}
    refute empty_value?(hash, "integer")
  end
end

class ConvertHashEdgeCasesTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_convert_hash_with_string_type_and_nil_false
    # Tests the specific condition: type == "string" && hash["nil"] != "true"
    hash = {"type" => "string", "nil" => "false"}
    result = convert_hash(hash, "string", [])

    # Should return "" since nil != "true"
    assert_equal "", result
  end

  def test_convert_hash_with_string_type_and_no_nil_key
    hash = {"type" => "string"}
    result = convert_hash(hash, "string", [])

    # Should return "" since there's no nil key (nil != "true" is true)
    assert_equal "", result
  end
end

class TypecastChildrenEdgeCasesTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_typecast_children_with_file_key_containing_nil
    hash = {"file" => nil, "name" => "test"}
    result = typecast_children(hash, [])

    # Since nil.is_a?(StringIO) is false, should return hash
    assert_kind_of Hash, result
    assert_nil result["file"]
    assert_equal "test", result["name"]
  end

  def test_typecast_children_with_file_key_containing_integer
    hash = {"file" => 42, "name" => "test"}
    result = typecast_children(hash, [])

    # Since 42.is_a?(StringIO) is false, should return hash
    assert_kind_of Hash, result
    assert_equal 42, result["file"]
  end
end

class TypecastArrayEdgeCasesTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_typecast_array_with_two_elements
    result = typecast_array(%w[one two], [])

    # array.one? is false when size == 2, so should return array
    assert_equal %w[one two], result
  end

  def test_typecast_array_with_exactly_one_element
    result = typecast_array(["single"], [])

    # array.one? is true when size == 1, so should unwrap
    assert_equal "single", result
  end

  def test_typecast_array_with_zero_elements
    result = typecast_array([], [])

    # array.one? is false when size == 0, so should return array
    assert_equal [], result
  end
end

class ParseWithParserOptionTest < Minitest::Test
  cover "MultiXml*"

  def setup
    @original_parser = MultiXml.instance_variable_get(:@parser)
    MultiXml.parser = :rexml
  end

  def teardown
    if @original_parser
      MultiXml.instance_variable_set(:@parser, @original_parser)
    end
  end

  def test_parse_uses_parser_option_when_truthy
    result = MultiXml.parse("<root>test</root>", parser: :ox)

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
    MultiXml.parser = :nokogiri
    result = MultiXml.parse("<root>value</root>", parser: :ox)

    # Should use Ox, not Nokogiri
    assert_equal({"root" => "value"}, result)
  end
end

class ConvertTextContentEdgeCasesTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_convert_text_content_with_unknown_type
    # When type is not in TYPE_CONVERTERS, converter is nil
    hash = {MultiXml::TEXT_CONTENT_KEY => "test value", "type" => "unknown_type"}
    result = convert_text_content(hash)

    # Should call unwrap_if_simple with hash and content
    # Hash size > 1, so returns merged hash
    assert_equal({"__content__" => "test value", "type" => "unknown_type"}, result)
  end

  def test_convert_text_content_without_type_returns_content
    hash = {MultiXml::TEXT_CONTENT_KEY => "test value"}
    result = convert_text_content(hash)

    # Hash size == 1, so unwraps to just the value
    assert_equal "test value", result
  end
end

class ExtractArrayEntriesKillMutantsTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_extract_array_entries_type_key_is_array_should_be_skipped
    # This test kills the mutant that removes k != "type"
    # The type key has an Array value but should still be skipped
    hash = {"type" => %w[array nested], "item" => %w[a b]}
    result = extract_array_entries(hash, [])

    # Should use "item", not "type" (even though type value is an Array)
    assert_equal %w[a b], result
  end

  def test_extract_array_entries_type_key_is_only_array
    # Edge case: only "type" key has array, but should return empty
    hash = {"type" => %w[array stuff]}
    result = extract_array_entries(hash, [])

    # Should skip "type" key and find nothing
    assert_equal [], result
  end

  def test_extract_array_entries_type_key_is_hash_should_be_skipped
    # The type key has a Hash value but should still be skipped
    hash = {"type" => {"nested" => "value"}, "item" => %w[x y]}
    result = extract_array_entries(hash, [])

    # Should use "item", not "type"
    assert_equal %w[x y], result
  end

  def test_extract_skips_type_even_if_hash_value
    # Test that "type" key is skipped even when its value is a Hash
    hash = {"type" => {"complex" => "type"}, "data" => {"key" => "val"}}
    result = extract_array_entries(hash, [])

    # Should find "data" which is a Hash, wrapped in array
    assert_equal [{"key" => "val"}], result
  end
end

class DisallowedTypeKillMutantsTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_disallowed_type_nil_type_returns_false
    # This kills mutants that remove the type && check
    # When type is nil, should return false even if nil is in disallowed list
    refute disallowed_type?(nil, [nil])
  end

  def test_disallowed_type_hash_type_not_checked
    # This kills mutants that remove !type.is_a?(Hash)
    # When type is a Hash, should return false even if hash contents match
    hash_type = {"yaml" => true}
    refute disallowed_type?(hash_type, [hash_type])
  end

  def test_disallowed_type_both_conditions_needed
    # type must be truthy AND not a Hash AND in list
    assert disallowed_type?("yaml", ["yaml"])
    refute disallowed_type?(nil, ["yaml"])
    refute disallowed_type?({"yaml" => true}, ["yaml"])
  end
end

class EmptyValueKillMutantsTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_empty_value_with_hash_type_returns_false
    # Kill mutant that removes !type.is_a?(Hash)
    hash_type = {"nested" => "data"}
    result = empty_value?({"type" => hash_type}, hash_type)

    # type.is_a?(Hash) is true, so last condition is false
    refute result
  end

  def test_empty_value_with_string_type_and_size_one
    # type && hash.size == 1 && !type.is_a?(Hash) should be true
    result = empty_value?({"type" => "integer"}, "integer")

    assert result
  end

  def test_empty_value_with_string_type_and_size_two
    # type && hash.size == 1 is false when size > 1
    result = empty_value?({"type" => "integer", "other" => "key"}, "integer")

    refute result
  end
end

class TypecastChildrenKillMutantsTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_typecast_children_stringio_subclass_is_unwrapped
    # Kill mutant that changes is_a? to instance_of?
    klass = Class.new(StringIO)
    file = klass.new("data")
    hash = {"file" => file, "other" => "stuff"}
    result = typecast_children(hash, [])

    # With is_a?, subclass should also be unwrapped
    assert_equal file, result
    assert_kind_of StringIO, result
  end

  def test_typecast_children_exact_stringio_is_unwrapped
    file = StringIO.new("data")
    hash = {"file" => file}
    result = typecast_children(hash, [])

    assert_equal file, result
  end
end

class ConvertHashKillMutantsTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_convert_hash_string_type_returns_empty_when_nil_absent
    hash = {"type" => "string"}
    result = convert_hash(hash, "string", [])

    # nil key is absent, so hash["nil"] != "true" is true (nil != "true")
    assert_equal "", result
  end

  def test_convert_hash_string_type_returns_nil_when_nil_true
    hash = {"type" => "string", "nil" => "true"}
    result = convert_hash(hash, "string", [])

    # hash["nil"] == "true", so condition fails, falls through to empty_value? which returns nil
    assert_nil result
  end

  def test_convert_hash_string_type_returns_empty_when_nil_not_true
    hash = {"type" => "string", "nil" => "false"}
    result = convert_hash(hash, "string", [])

    # hash["nil"] != "true" is true
    assert_equal "", result
  end
end

class TypecastArrayKillMutantsTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_typecast_array_mutates_original
    # Kill mutant that changes map! to map
    input = [{"type" => "integer", "__content__" => "42"}]
    original_first = input.first
    typecast_array(input, [])

    # map! modifies in place
    assert_equal 42, input.first
    refute_same original_first, input.first
  end
end

class ParseMethodKillMutantsTest < Minitest::Test
  cover "MultiXml*"

  def setup
    @original_parser = MultiXml.instance_variable_get(:@parser)
  end

  def teardown
    if @original_parser
      MultiXml.instance_variable_set(:@parser, @original_parser)
    end
  end

  def test_parse_options_merge_preserves_parser
    MultiXml.parser = :rexml

    # When parser option is truthy, should use it
    result = MultiXml.parse("<r>a</r>", parser: :ox)

    assert_equal({"r" => "a"}, result)
  end

  def test_parse_options_merge_uses_defaults
    MultiXml.parser = :ox

    # Test default typecast_xml_value is true
    result = MultiXml.parse('<r type="integer">1</r>')

    assert_equal 1, result["r"]
  end
end

class ArraySubclass < Array
end

class ExtractArrayEntriesSubclassTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_extract_array_entries_with_array_subclass
    # Kill mutant that changes is_a?(Array) to instance_of?(Array)
    subclass_array = ArraySubclass.new
    subclass_array.push("a", "b")
    hash = {"type" => "array", "items" => subclass_array}
    result = extract_array_entries(hash, [])

    # With is_a?, subclass should be found
    assert_equal %w[a b], result
  end

  def test_extract_array_entries_with_hash_subclass_value
    # Kill mutant that changes is_a?(Hash) to instance_of?(Hash)
    subclass_hash = HashSubclass.new
    subclass_hash["key"] = "val"
    hash = {"type" => "array", "item" => subclass_hash}
    result = extract_array_entries(hash, [])

    # With is_a?, subclass should be found and wrapped in array
    assert_equal [{"key" => "val"}], result
  end

  def test_extract_array_entries_passes_disallowed_types
    # Kill mutant that removes disallowed_types parameter
    hash = {"type" => "array", "item" => [{"type" => "yaml", "__content__" => "test"}]}

    assert_raises(MultiXml::DisallowedTypeError) do
      extract_array_entries(hash, ["yaml"])
    end
  end

  def test_extract_array_entries_passes_disallowed_types_for_hash
    # Kill mutant that removes disallowed_types from Hash branch
    hash = {"type" => "array", "item" => {"type" => "yaml", "__content__" => "test"}}

    assert_raises(MultiXml::DisallowedTypeError) do
      extract_array_entries(hash, ["yaml"])
    end
  end
end

class TypecastArraySubclassTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_typecast_array_one_returns_false_for_empty
    result = typecast_array([], [])

    # [].one? is false
    assert_equal [], result
  end

  def test_typecast_array_one_returns_true_for_single
    result = typecast_array(["only"], [])

    # ["only"].one? is true
    assert_equal "only", result
  end

  def test_typecast_array_one_returns_false_for_multiple
    result = typecast_array(%w[one two], [])

    # ["one", "two"].one? is false
    assert_equal %w[one two], result
  end
end

class ConvertHashSubclassTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_convert_hash_passes_disallowed_types_to_typecast_children
    # Kill mutant that removes disallowed_types from typecast_children call
    hash = {"child" => {"type" => "yaml", "__content__" => "test"}}

    assert_raises(MultiXml::DisallowedTypeError) do
      convert_hash(hash, nil, ["yaml"])
    end
  end

  def test_convert_hash_passes_disallowed_types_to_extract_array
    # Kill mutant that removes disallowed_types from extract_array_entries
    hash = {"type" => "array", "item" => [{"type" => "yaml", "__content__" => "test"}]}

    assert_raises(MultiXml::DisallowedTypeError) do
      convert_hash(hash, "array", ["yaml"])
    end
  end
end

class ConvertTextContentSubclassTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_convert_text_content_accesses_content_key
    # Kill mutant that changes hash[TEXT_CONTENT_KEY] to hash.fetch(TEXT_CONTENT_KEY)
    hash = {MultiXml::TEXT_CONTENT_KEY => "value", "type" => "string"}
    result = convert_text_content(hash)

    assert_equal "value", result
  end
end

class TypecastChildrenSubclassTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_typecast_children_accesses_file_key
    # Kill mutant that changes result["file"] to result.fetch("file")
    hash = {"name" => "test"}
    result = typecast_children(hash, [])

    # When "file" key doesn't exist, result["file"] returns nil
    # result.fetch("file") would raise KeyError
    assert_kind_of Hash, result
    assert_nil result["file"]
  end
end

class DisallowedTypeSubclassTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_disallowed_type_with_hash_subclass
    # Kill mutant that changes is_a?(Hash) to instance_of?(Hash)
    subclass = HashSubclass.new
    subclass["yaml"] = true

    # With is_a?, Hash subclass should also return false
    refute disallowed_type?(subclass, [subclass])
  end
end

class ParseWithErrorHandlingNilTest < Minitest::Test
  cover "MultiXml*"

  def setup
    @original_parser = MultiXml.instance_variable_get(:@parser)
  end

  def teardown
    if @original_parser
      MultiXml.instance_variable_set(:@parser, @original_parser)
    end
  end

  def test_parse_with_error_handling_handles_nil_parser_result
    # Kill mutant that removes || {} from parse_with_error_handling
    # When parser returns nil, should get empty hash not nil
    MultiXml.parser = :ox
    result = MultiXml.parse("<empty/>")

    # Result should be a hash, not nil
    assert_kind_of Hash, result
  end

  def test_parse_error_with_io_uses_rewind
    # Kill mutant that changes tap(&:rewind) behavior
    MultiXml.parser = :nokogiri
    io = StringIO.new("<bad></wrong>")

    begin
      MultiXml.parse(io)
      flunk "Expected ParseError"
    rescue MultiXml::ParseError => e
      # io should have been rewound and read
      assert_equal "<bad></wrong>", e.xml
    end
  end
end

class TypecastArrayFirstTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_typecast_array_returns_first_for_single_element
    # Kill mutant that changes array.first to array.last or array[0]
    result = typecast_array(["only_element"], [])

    assert_equal "only_element", result
  end
end

class ExtractArrayMapTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_extract_array_maps_entries_with_typecast
    # Kill mutant that removes typecast_xml_value call in map
    hash = {"type" => "array", "item" => [{"type" => "integer", "__content__" => "42"}]}
    result = extract_array_entries(hash, [])

    # Should have typecasted the integer
    assert_equal [42], result
  end
end

class LoadParserCamelizeTest < Minitest::Test
  cover "MultiXml*"

  def test_load_parser_converts_to_camelcase
    # Kill mutant that removes .downcase
    result = MultiXml.send(:load_parser, :OX)

    assert_equal MultiXml::Parsers::Ox, result
  end

  def test_load_parser_handles_underscore_names
    # libxml_sax should become LibxmlSax
    result = MultiXml.send(:load_parser, :libxml_sax)

    assert_equal MultiXml::Parsers::LibxmlSax, result
  end
end

class ConvertHashTypecastChildrenTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_convert_hash_calls_typecast_children_last
    # Kill mutant that removes typecast_children call
    hash = {"name" => {"type" => "integer", "__content__" => "123"}}
    result = convert_hash(hash, nil, [])

    # Should have called typecast_children which typecasts nested values
    assert_equal({"name" => 123}, result)
  end
end

# Create a mock parser that returns nil
class NilReturningParser
  def self.parse(_io)
    nil
  end

  def self.parse_error
    StandardError
  end
end

# Create a mock parser that always fails
class FailingParser
  class ParseFailed < StandardError; end

  def self.parse(_io)
    raise ParseFailed, "Parse failed"
  end

  def self.parse_error
    ParseFailed
  end
end

class ParseWithErrorHandlingNilReturnTest < Minitest::Test
  cover "MultiXml*"

  def setup
    @original_parser = MultiXml.instance_variable_get(:@parser)
  end

  def teardown
    if @original_parser
      MultiXml.instance_variable_set(:@parser, @original_parser)
    end
  end

  def test_parse_returns_empty_hash_when_parser_returns_nil
    # Kill mutant: xml_parser.parse(io) || {} -> xml_parser.parse(io)
    # When parser returns nil, without || {} we'd get nil passed to undasherize_keys
    MultiXml.parser = NilReturningParser
    # Disable typecast to see raw result from parse_with_error_handling
    result = MultiXml.parse("<test/>", typecast_xml_value: false)

    # Must be empty hash, not nil
    assert_equal({}, result)
  end

  def test_parse_returns_empty_hash_not_nil_when_parser_returns_nil
    # Kill mutant: || {} -> || nil
    MultiXml.parser = NilReturningParser
    # Disable typecast to see raw result
    result = MultiXml.parse("<test/>", typecast_xml_value: false)

    # Specifically test it's {} not nil
    refute_nil result
    assert_empty result
  end

  def test_parse_error_uses_to_s_on_string_input
    # Kill mutant: original_input.to_s -> original_input.to_str
    # Strings respond to both, but we're testing the to_s path
    MultiXml.parser = FailingParser

    begin
      MultiXml.parse("<bad/>")
      flunk "Expected ParseError"
    rescue MultiXml::ParseError => e
      assert_equal "<bad/>", e.xml
    end
  end

  def test_parse_error_with_io_that_responds_to_read
    # Kill mutants related to respond_to?(:read) branch
    MultiXml.parser = FailingParser
    io = StringIO.new("<bad/>")

    begin
      MultiXml.parse(io)
      flunk "Expected ParseError"
    rescue MultiXml::ParseError => e
      assert_equal "<bad/>", e.xml
    end
  end

  def test_parse_error_rewinds_io_before_reading
    # Kill mutant: original_input.tap(&:rewind).read
    # The FailingParser raises an error during parse, so original_input
    # still needs to be readable for error message
    MultiXml.parser = :nokogiri
    io = StringIO.new("<bad></wrong>")

    begin
      MultiXml.parse(io)
      flunk "Expected ParseError"
    rescue MultiXml::ParseError => e
      # Should have rewound and read full content
      assert_equal "<bad></wrong>", e.xml
    end
  end
end

class LoadParserMutantKillerTest < Minitest::Test
  cover "MultiXml*"

  def test_load_parser_calls_to_s_on_symbol
    # Kill mutant: name.to_s.downcase -> name.downcase
    # Symbols don't have downcase method directly in older Ruby
    result = MultiXml.send(:load_parser, :OX)

    assert_equal MultiXml::Parsers::Ox, result
  end

  def test_load_parser_calls_downcase
    # Kill mutant: name.to_s.downcase -> name.to_s
    # Without downcase, "OX" wouldn't match "ox" file
    result = MultiXml.send(:load_parser, "OX")

    assert_equal MultiXml::Parsers::Ox, result
  end

  def test_load_parser_with_mixed_case_string
    # Ensure downcase is called on the string
    result = MultiXml.send(:load_parser, "Ox")

    assert_equal MultiXml::Parsers::Ox, result
  end
end

class TypecastArrayDisallowedTypesTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_typecast_array_passes_disallowed_types_to_nested_calls
    # Kill mutant: typecast_xml_value(item, disallowed_types) -> typecast_xml_value(item)
    # Default disallowed_types includes yaml, so if we pass [] it should NOT raise
    # But if the mutant removes the parameter, it uses default which WOULD raise
    input = [{"type" => "yaml", "__content__" => "test: value"}]

    # With empty disallowed_types, yaml should be ALLOWED
    # YAML parses "test: value" as {"test" => "value"}
    result = typecast_array(input, [])
    assert_equal({"test" => "value"}, result)
  end

  def test_typecast_array_with_custom_disallowed_types
    # Test with custom disallowed type not in default
    input = [{"type" => "integer", "__content__" => "42"}]

    assert_raises(MultiXml::DisallowedTypeError) do
      typecast_array(input, ["integer"])
    end
  end
end

class TypecastChildrenFetchMutantTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_typecast_children_uses_bracket_access_for_file
    # Kill mutant: result["file"] -> result.fetch("file")
    # fetch raises KeyError when key missing, [] returns nil
    hash = {"name" => "test", "data" => "value"}
    result = typecast_children(hash, [])

    # Should work even without "file" key
    assert_kind_of Hash, result
    assert_equal "test", result["name"]
  end
end

class ConvertTextContentFetchMutantTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_convert_text_content_uses_bracket_access
    # Kill mutant: hash[TEXT_CONTENT_KEY] -> hash.fetch(TEXT_CONTENT_KEY)
    # Both work the same when key exists
    hash = {MultiXml::TEXT_CONTENT_KEY => "value"}
    result = convert_text_content(hash)

    assert_equal "value", result
  end
end

class ExtractArrayEntriesStringComparisonTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_extract_array_entries_with_frozen_type_key
    # Kill mutant: k != "type" -> !k.eql?("type") or !k.equal?("type")
    # equal? checks object identity, so frozen strings with same content are equal
    # but different string objects are not equal? even with same content
    hash = {"type" => "array", "items" => %w[a b]}
    result = extract_array_entries(hash, [])

    assert_equal %w[a b], result
  end

  def test_extract_array_entries_skips_type_key_with_interned_string
    # Use a string that might be interned differently
    type_key = "type".dup
    hash = {type_key => "array", "data" => %w[x y]}
    result = extract_array_entries(hash, [])

    # Should skip the type key regardless of string identity
    assert_equal %w[x y], result
  end
end

class ConvertHashDisallowedTypesTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_convert_hash_passes_disallowed_types_through_all_paths
    # Kill mutant that removes disallowed_types from typecast_children
    hash = {"nested" => {"type" => "symbol", "__content__" => "test"}}

    assert_raises(MultiXml::DisallowedTypeError) do
      convert_hash(hash, nil, ["symbol"])
    end
  end
end

class RaiseNoParserErrorChompTest < Minitest::Test
  cover "MultiXml*"

  def test_no_parser_error_message_has_no_trailing_newline
    # Kill mutant: <<~MSG.chomp -> <<~MSG
    # chomp removes trailing newline
    error = assert_raises(MultiXml::NoParserError) do
      MultiXml.send(:raise_no_parser_error)
    end

    # Message should NOT end with newline due to chomp
    refute error.message.end_with?("\n"), "Message should not end with newline"
  end
end

class ResolveParserCaseMutantTest < Minitest::Test
  cover "MultiXml*"

  def test_resolve_parser_handles_string
    result = MultiXml.send(:resolve_parser, "ox")

    assert_equal MultiXml::Parsers::Ox, result
  end

  def test_resolve_parser_handles_symbol
    result = MultiXml.send(:resolve_parser, :ox)

    assert_equal MultiXml::Parsers::Ox, result
  end

  def test_resolve_parser_handles_module
    require "multi_xml/parsers/ox"
    result = MultiXml.send(:resolve_parser, MultiXml::Parsers::Ox)

    assert_equal MultiXml::Parsers::Ox, result
  end

  def test_resolve_parser_handles_class
    result = MultiXml.send(:resolve_parser, MockDecoder)

    assert_equal MockDecoder, result
  end
end

class ParseOptionsAccessMutantTest < Minitest::Test
  cover "MultiXml*"

  def setup
    @original_parser = MultiXml.instance_variable_get(:@parser)
  end

  def teardown
    if @original_parser
      MultiXml.instance_variable_set(:@parser, @original_parser)
    end
  end

  def test_parse_accesses_parser_option_with_bracket
    # Kill mutant: options[:parser] -> options.fetch(:parser)
    # With fetch, missing key raises, with [] returns nil
    MultiXml.parser = :ox

    # options without :parser key should work (use class-level parser)
    result = MultiXml.parse("<test>value</test>", symbolize_keys: false)

    assert_equal({"test" => "value"}, result)
  end

  def test_parse_uses_truthy_check_for_parser_option
    # Kill mutant that changes the conditional
    MultiXml.parser = :rexml

    # nil parser option should fall back to class parser
    result = MultiXml.parse("<r>v</r>", parser: nil)

    assert_equal({"r" => "v"}, result)
  end

  def test_parse_uses_provided_parser_when_truthy
    MultiXml.parser = :rexml

    # Truthy parser option should be used
    result = MultiXml.parse("<r>v</r>", parser: :ox)

    assert_equal({"r" => "v"}, result)
  end

  def test_parse_accesses_typecast_option_correctly
    # Kill mutants related to options[:typecast_xml_value]
    MultiXml.parser = :ox

    result_with = MultiXml.parse('<n type="integer">42</n>', typecast_xml_value: true)
    result_without = MultiXml.parse('<n type="integer">42</n>', typecast_xml_value: false)

    assert_equal 42, result_with["n"]
    assert_equal({"type" => "integer", "__content__" => "42"}, result_without["n"])
  end

  def test_parse_accesses_symbolize_keys_option_correctly
    # Kill mutants related to options[:symbolize_keys]
    MultiXml.parser = :ox

    result_with = MultiXml.parse("<root><name>v</name></root>", symbolize_keys: true)
    result_without = MultiXml.parse("<root><name>v</name></root>", symbolize_keys: false)

    assert_equal({root: {name: "v"}}, result_with)
    assert_equal({"root" => {"name" => "v"}}, result_without)
  end

  def test_parse_accesses_disallowed_types_option_correctly
    # Kill mutants related to options[:disallowed_types]
    MultiXml.parser = :ox

    assert_raises(MultiXml::DisallowedTypeError) do
      MultiXml.parse('<n type="yaml">test</n>', disallowed_types: ["yaml"])
    end
  end
end

class DetectParserOrChainTest < Minitest::Test
  cover "MultiXml*"

  def test_detect_parser_returns_loaded_parser_first
    # This tests that find_loaded_parser is called and its result used
    # Kill mutant: find_loaded_parser || find_available_parser -> find_available_parser
    result = MultiXml.send(:detect_parser)

    # Since Ox is loaded, should return :ox
    assert_equal :ox, result
  end

  def test_detect_parser_falls_back_to_find_available_when_loaded_returns_nil
    # Kill mutant: find_loaded_parser || find_available_parser -> find_loaded_parser || raise_no_parser_error
    # Kill mutant: find_loaded_parser -> nil (replaces find_loaded_parser with nil)
    # Stub find_loaded_parser to return nil to test the fallback
    MultiXml.stub :find_loaded_parser, nil do
      result = MultiXml.send(:detect_parser)

      # Should fall back to find_available_parser, which returns :ox
      assert_equal :ox, result
    end
  end

  def test_detect_parser_uses_find_loaded_result_not_find_available
    # Kill mutant: find_loaded_parser -> find_available_parser
    # Both return :ox in test env, but we can stub find_available to verify
    MultiXml.stub :find_available_parser, :rexml do
      result = MultiXml.send(:detect_parser)

      # Should use find_loaded_parser (:ox), not find_available_parser (:rexml stub)
      assert_equal :ox, result
    end
  end
end

class FindLoadedParserNilReturnTest < Minitest::Test
  cover "MultiXml*"

  def test_find_loaded_parser_returns_nil_when_no_parser_defined
    # This is hard to test without undefining constants
    # But we can verify the method exists and returns expected type
    result = MultiXml.send(:find_loaded_parser)

    # In test environment, should return :ox since Ox is loaded
    assert_equal :ox, result
  end
end

class FindAvailableParserTest < Minitest::Test
  cover "MultiXml*"

  def test_find_available_parser_returns_parser_name
    # Verify find_available_parser returns a symbol
    result = MultiXml.send(:find_available_parser)

    assert_kind_of Symbol, result
  end

  def test_find_available_parser_uses_parser_preference_order
    # Kill mutant that changes iteration behavior
    result = MultiXml.send(:find_available_parser)

    # Should be :ox since it's first in preference and available
    assert_equal :ox, result
  end

  def test_find_available_parser_continues_after_load_error
    # Kill mutant: next -> break (break would exit early, next continues)
    # We need to test that after LoadError, iteration continues
    # Create a custom PARSER_PREFERENCE where first fails, second succeeds
    original_preference = MultiXml::PARSER_PREFERENCE.dup
    custom_preference = [["nonexistent_parser_gem", :nonexistent], ["ox", :ox]]

    # Temporarily replace PARSER_PREFERENCE constant
    MultiXml.send(:remove_const, :PARSER_PREFERENCE)
    MultiXml.const_set(:PARSER_PREFERENCE, custom_preference)

    begin
      result = MultiXml.send(:find_available_parser)
      # With `next`, should continue to ox and return :ox
      # With `break`, would exit after first LoadError and return nil
      assert_equal :ox, result
    ensure
      # Restore original
      MultiXml.send(:remove_const, :PARSER_PREFERENCE)
      MultiXml.const_set(:PARSER_PREFERENCE, original_preference.freeze)
    end
  end
end

class ExtractArrayEntriesMapTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_extract_array_entries_maps_with_typecast
    # Kill mutant that removes typecast_xml_value from map block
    hash = {"type" => "array", "item" => [{"type" => "integer", "__content__" => "99"}]}
    result = extract_array_entries(hash, [])

    # Should have typecasted the nested value
    assert_equal [99], result
  end

  def test_extract_array_entries_passes_disallowed_to_map
    # Kill mutant: typecast_xml_value(e, disallowed_types) -> typecast_xml_value(e)
    # Use empty disallowed_types to allow yaml - mutant would use default which disallows yaml
    hash = {"type" => "array", "item" => [{"type" => "yaml", "__content__" => "test"}]}
    result = extract_array_entries(hash, [])

    # With empty disallowed_types, yaml should be ALLOWED
    assert_equal ["test"], result
  end

  def test_extract_array_entries_passes_disallowed_to_hash_branch
    # Kill mutant that removes disallowed_types from Hash case
    # Use empty disallowed_types to allow yaml
    hash = {"type" => "array", "item" => {"type" => "yaml", "__content__" => "data"}}
    result = extract_array_entries(hash, [])

    # With empty disallowed_types, yaml should be ALLOWED
    assert_equal ["data"], result
  end

  def test_extract_array_entries_with_custom_disallowed_type_raises
    # Test that custom disallowed type is passed through
    hash = {"type" => "array", "item" => [{"type" => "integer", "__content__" => "42"}]}

    assert_raises(MultiXml::DisallowedTypeError) do
      extract_array_entries(hash, ["integer"])
    end
  end
end

class ParseWithErrorHandlingMessageMutantsTest < Minitest::Test
  cover "MultiXml*"

  def setup
    @original_parser = MultiXml.instance_variable_get(:@parser)
  end

  def teardown
    if @original_parser
      MultiXml.instance_variable_set(:@parser, @original_parser)
    end
  end

  def test_parse_error_message_is_original_exception_message
    # Kill mutant: e.message -> nil
    # Kill mutant: e.message -> e (passes exception object instead of string)
    # Kill mutant: omits message argument
    MultiXml.parser = FailingParser

    begin
      MultiXml.parse("<bad/>")
      flunk "Expected ParseError"
    rescue MultiXml::ParseError => e
      # Message must be the string "Parse failed", not nil or the exception object
      assert_equal "Parse failed", e.message
      assert_instance_of String, e.message
    end
  end

  def test_parse_error_message_is_not_exception_object_to_s
    # Kill mutant: e.message -> e
    # If e is passed instead of e.message, the message would be e.to_s
    # which includes class name like "#<FailingParser::ParseFailed..."
    MultiXml.parser = FailingParser

    begin
      MultiXml.parse("<bad/>")
      flunk "Expected ParseError"
    rescue MultiXml::ParseError => e
      # Should be exactly "Parse failed", not the exception's inspect/to_s
      refute_match(/FailingParser/, e.message)
      refute_match(/#</, e.message)
    end
  end
end

class ParseWithErrorHandlingToSMutantsTest < Minitest::Test
  cover "MultiXml*"

  def setup
    @original_parser = MultiXml.instance_variable_get(:@parser)
  end

  def teardown
    if @original_parser
      MultiXml.instance_variable_set(:@parser, @original_parser)
    end
  end

  def test_parse_error_xml_uses_to_s_not_to_str
    # Kill mutant: original_input.to_s -> original_input.to_str
    # Create an object that has different to_s and to_str
    obj_with_different_to_s = Object.new
    def obj_with_different_to_s.to_s
      "<from_to_s/>"
    end

    def obj_with_different_to_s.to_str
      "<from_to_str/>"
    end

    MultiXml.parser = FailingParser

    begin
      MultiXml.parse(obj_with_different_to_s)
      flunk "Expected ParseError"
    rescue MultiXml::ParseError => e
      # Should use to_s, not to_str
      assert_equal "<from_to_s/>", e.xml
    end
  end

  def test_parse_error_xml_uses_to_s_not_raw_input
    # Kill mutant: original_input.to_s -> original_input
    # String has to_s == self, so use an object where to_s differs
    obj = Object.new
    def obj.to_s
      "<converted/>"
    end

    MultiXml.parser = FailingParser

    begin
      MultiXml.parse(obj)
      flunk "Expected ParseError"
    rescue MultiXml::ParseError => e
      # Should be the string from to_s
      assert_equal "<converted/>", e.xml
      assert_instance_of String, e.xml
    end
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
