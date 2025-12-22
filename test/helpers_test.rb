require "test_helper"
require "mutant/minitest/coverage"

# Tests for DateTimeFallbackTest
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

# Tests for RexmlArrayBranchTest
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

# Tests for TypecastXmlValueHelpersTest
class TypecastXmlValueHelpersTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_typecast_xml_value_uses_default_disallowed_types
    assert_raises(MultiXml::DisallowedTypeError) do
      typecast_xml_value({"type" => "yaml", "__content__" => "test"})
    end
  end

  def test_typecast_xml_value_with_explicit_empty_disallowed_types
    result = typecast_xml_value({"type" => "yaml", "__content__" => "test"}, [])

    assert_equal "test", result
  end
end

# Tests for TypecastArrayHelpersTest
class TypecastArrayHelpersTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_typecast_array_with_single_element_returns_first
    assert_equal({"key" => "value"}, typecast_array([{"key" => "value"}], []))
  end

  def test_typecast_array_with_multiple_elements_returns_array
    assert_equal [{"a" => 1}, {"b" => 2}], typecast_array([{"a" => 1}, {"b" => 2}], [])
  end

  def test_typecast_array_with_empty_array
    assert_empty typecast_array([], [])
  end

  def test_typecast_array_recursively_typecasts
    assert_equal 42, typecast_array([{"type" => "integer", "__content__" => "42"}], [])
  end
end

# Tests for TypecastChildrenHelpersTest
class TypecastChildrenHelpersTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_typecast_children_unwraps_stringio_file
    file = StringIO.new("content")

    assert_same file, typecast_children({"file" => file, "other" => "data"}, [])
  end

  def test_typecast_children_returns_hash_when_file_not_stringio
    result = typecast_children({"file" => "not a stringio", "other" => "data"}, [])

    assert_kind_of Hash, result
    assert_equal "not a stringio", result["file"]
  end

  def test_typecast_children_returns_hash_when_no_file_key
    result = typecast_children({"name" => "value", "other" => "data"}, [])

    assert_kind_of Hash, result
    assert_equal "value", result["name"]
  end

  def test_typecast_children_returns_hash_when_file_is_nil
    result = typecast_children({"file" => nil, "other" => "data"}, [])

    assert_kind_of Hash, result
    assert_nil result["file"]
  end
end

# Tests for ExtractArrayEntriesHelpersTest
class ExtractArrayEntriesHelpersTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_extract_array_entries_with_array_value
    assert_equal %w[Alice Bob], extract_array_entries({"type" => "array", "user" => %w[Alice Bob]}, [])
  end

  def test_extract_array_entries_with_hash_value
    assert_equal [{"name" => "Alice"}], extract_array_entries({"type" => "array", "user" => {"name" => "Alice"}}, [])
  end

  def test_extract_array_entries_with_no_entries
    assert_empty extract_array_entries({"type" => "array"}, [])
  end

  def test_extract_array_entries_ignores_type_key
    assert_equal %w[a b], extract_array_entries({"type" => "array", "item" => %w[a b]}, [])
  end
end

# Tests for DisallowedTypeHelpersTest
class DisallowedTypeHelpersTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_disallowed_type_returns_true_for_disallowed
    assert disallowed_type?("yaml", %w[yaml symbol])
  end

  def test_disallowed_type_returns_false_for_allowed
    refute disallowed_type?("string", %w[yaml symbol])
  end

  def test_disallowed_type_returns_false_for_nil_type
    refute disallowed_type?(nil, %w[yaml symbol])
  end

  def test_disallowed_type_returns_false_when_type_is_hash
    refute disallowed_type?({"nested" => "value"}, ["yaml"])
  end
end

# Tests for EmptyValueHelpersTest
class EmptyValueHelpersTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

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
end

# Tests for ConvertHashHelpersTest
class ConvertHashHelpersTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_convert_hash_returns_empty_string_for_string_type_without_nil_true
    assert_equal "", convert_hash({"type" => "string"}, "string", [])
  end

  def test_convert_hash_returns_nil_for_string_type_with_nil_true
    assert_nil convert_hash({"type" => "string", "nil" => "true"}, "string", [])
  end
end

# Tests for KeyTransformHelpersTest
class KeyTransformHelpersTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_undasherize_keys_with_array
    input = [{"first-name" => "John"}, {"last-name" => "Doe"}]

    assert_equal [{"first_name" => "John"}, {"last_name" => "Doe"}], undasherize_keys(input)
  end

  def test_undasherize_keys_with_nested_array
    assert_equal({"users" => [{"first_name" => "John"}]}, undasherize_keys({"users" => [{"first-name" => "John"}]}))
  end

  def test_undasherize_keys_with_plain_value
    assert_equal "plain string", undasherize_keys("plain string")
  end

  def test_symbolize_keys_with_array
    assert_equal [{name: "John"}, {name: "Jane"}], symbolize_keys([{"name" => "John"}, {"name" => "Jane"}])
  end
end

# Tests for TypecastHashTest
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

# Tests for ConvertTextContentTest
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

# Tests for RaiseNoParserErrorTest
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

# Tests for RaiseNoParserErrorChompTest
class RaiseNoParserErrorChompTest < Minitest::Test
  cover "MultiXml*"

  def test_no_parser_error_message_has_no_trailing_newline
    # chomp removes trailing newline
    error = assert_raises(MultiXml::NoParserError) do
      MultiXml.send(:raise_no_parser_error)
    end

    # Message should NOT end with newline due to chomp
    refute error.message.end_with?("\n"), "Message should not end with newline"
  end
end
