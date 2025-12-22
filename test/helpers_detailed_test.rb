require "test_helper"
require "mutant/minitest/coverage"

# Tests for DisallowedTypeDetailedTest
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

# Tests for EmptyValueDetailedTest
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

# Tests for ExtractArrayEntriesDetailedTest
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

    assert_empty result
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

    assert_empty result
  end

  def test_extract_array_entries_with_nested_type_casting
    hash = {"type" => "array", "item" => [{"type" => "integer", "__content__" => "42"}]}
    result = extract_array_entries(hash, [])

    assert_equal [42], result
  end
end

# Tests for TypecastChildrenDetailedTest
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

# Tests for ConvertHashDetailedTest
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

# Tests for TypecastArrayDetailedTest
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

    assert_empty result
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

# Tests for ParseMethodDetailedTest
class ParseMethodDetailedTest < Minitest::Test
  cover "MultiXml*"

  def setup
    @original_parser = MultiXml.instance_variable_get(:@parser)
    MultiXml.parser = :ox
  end

  def teardown
    return unless @original_parser

    MultiXml.instance_variable_set(:@parser, @original_parser)
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

# Tests for ConvertTextContentEdgeCasesTest
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
