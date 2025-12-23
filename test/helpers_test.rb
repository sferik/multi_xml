require "test_helper"
require "mutant/minitest/coverage"

# Subclasses for testing is_a? vs instance_of? behavior
class HashSubclass < Hash
end

class ArraySubclass < Array
end

# Tests DateTime parsing fallback behavior
class DateTimeFallbackTest < Minitest::Test
  cover "MultiXml*"

  def test_parse_datetime_falls_back_to_datetime_for_iso_week_format
    converter = MultiXml::PARSE_DATETIME
    result = converter.call("2020-W01")

    assert_kind_of Time, result
    assert_equal Time.utc(2019, 12, 30), result
  end
end

# Tests REXML parser add_to_hash behavior
class RexmlArrayBranchTest < Minitest::Test
  cover "MultiXml*"

  def test_add_to_hash_wraps_array_value_in_array
    require "multi_xml/parsers/rexml"

    hash = {}
    value = %w[item1 item2]
    result = MultiXml::Parsers::Rexml.send(:add_to_hash, hash, "key", value)

    assert_equal [%w[item1 item2]], result["key"]
  end
end

# Tests typecast_xml_value with default and custom disallowed types
class TypecastXmlValueTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_uses_default_disallowed_types
    assert_raises(MultiXml::DisallowedTypeError) do
      typecast_xml_value({"type" => "yaml", "__content__" => "test"})
    end
  end

  def test_with_explicit_empty_disallowed_types
    result = typecast_xml_value({"type" => "yaml", "__content__" => "test"}, [])

    assert_equal "test", result
  end

  def test_passes_disallowed_types_to_array
    value = [{"type" => "yaml", "__content__" => "key: value"}, "second"]
    result = typecast_xml_value(value, [])

    assert_equal [{"key" => "value"}, "second"], result
  end

  def test_custom_disallowed_blocks_in_array
    value = [{"type" => "integer", "__content__" => "42"}]

    assert_raises(MultiXml::DisallowedTypeError) do
      typecast_xml_value(value, ["integer"])
    end
  end
end

# Tests typecast_array behavior including unwrapping single elements
class TypecastArrayTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_with_single_element_returns_first
    assert_equal({"key" => "value"}, typecast_array([{"key" => "value"}], []))
  end

  def test_with_multiple_elements_returns_array
    assert_equal [{"a" => 1}, {"b" => 2}], typecast_array([{"a" => 1}, {"b" => 2}], [])
  end

  def test_with_empty_array
    assert_empty typecast_array([], [])
  end

  def test_recursively_typecasts
    assert_equal 42, typecast_array([{"type" => "integer", "__content__" => "42"}], [])
  end

  def test_mutates_original
    input = [{"type" => "integer", "__content__" => "42"}]
    original_first = input.first
    typecast_array(input, [])

    assert_equal 42, input.first
    refute_same original_first, input.first
  end

  def test_one_returns_false_for_empty
    result = typecast_array([], [])

    assert_empty result
  end

  def test_one_returns_true_for_single
    result = typecast_array(["only"], [])

    assert_equal "only", result
  end

  def test_one_returns_false_for_multiple
    result = typecast_array(%w[one two], [])

    assert_equal %w[one two], result
  end

  def test_passes_disallowed_types_to_nested_calls
    input = [{"type" => "yaml", "__content__" => "test: value"}]
    result = typecast_array(input, [])

    assert_equal({"test" => "value"}, result)
  end

  def test_with_custom_disallowed_types
    input = [{"type" => "integer", "__content__" => "42"}]

    assert_raises(MultiXml::DisallowedTypeError) do
      typecast_array(input, ["integer"])
    end
  end
end

# Tests typecast_children behavior with StringIO file handling
class TypecastChildrenTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_unwraps_stringio_file
    file = StringIO.new("content")

    assert_same file, typecast_children({"file" => file, "other" => "data"}, [])
  end

  def test_returns_hash_when_file_not_stringio
    result = typecast_children({"file" => "not a stringio", "other" => "data"}, [])

    assert_kind_of Hash, result
    assert_equal "not a stringio", result["file"]
  end

  def test_returns_hash_when_no_file_key
    result = typecast_children({"name" => "value", "other" => "data"}, [])

    assert_kind_of Hash, result
    assert_equal "value", result["name"]
  end

  def test_returns_hash_when_file_is_nil
    result = typecast_children({"file" => nil, "other" => "data"}, [])

    assert_kind_of Hash, result
    assert_nil result["file"]
  end

  def test_stringio_subclass_is_unwrapped
    klass = Class.new(StringIO)
    file = klass.new("data")
    hash = {"file" => file, "other" => "stuff"}
    result = typecast_children(hash, [])

    assert_equal file, result
    assert_kind_of StringIO, result
  end

  def test_exact_stringio_is_unwrapped
    file = StringIO.new("data")
    hash = {"file" => file}
    result = typecast_children(hash, [])

    assert_equal file, result
  end

  def test_with_file_key_containing_integer
    hash = {"file" => 42, "name" => "test"}
    result = typecast_children(hash, [])

    assert_kind_of Hash, result
    assert_equal 42, result["file"]
  end

  def test_uses_bracket_access_for_file
    hash = {"name" => "test", "data" => "value"}
    result = typecast_children(hash, [])

    assert_kind_of Hash, result
    assert_equal "test", result["name"]
  end

  def test_returns_file_not_fetches
    file = StringIO.new("content")
    hash = {"file" => file}
    result = typecast_children(hash, [])

    assert_same file, result
  end
end

# Tests extract_array_entries for type="array" handling
class ExtractArrayEntriesTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_with_array_value
    assert_equal %w[Alice Bob], extract_array_entries({"type" => "array", "user" => %w[Alice Bob]}, [])
  end

  def test_with_hash_value
    assert_equal [{"name" => "Alice"}], extract_array_entries({"type" => "array", "user" => {"name" => "Alice"}}, [])
  end

  def test_with_no_entries
    assert_empty extract_array_entries({"type" => "array"}, [])
  end

  def test_ignores_type_key
    assert_equal %w[a b], extract_array_entries({"type" => "array", "item" => %w[a b]}, [])
  end

  def test_type_key_is_array_should_be_skipped
    hash = {"type" => %w[array nested], "item" => %w[a b]}
    result = extract_array_entries(hash, [])

    assert_equal %w[a b], result
  end

  def test_type_key_is_only_array
    hash = {"type" => %w[array stuff]}
    result = extract_array_entries(hash, [])

    assert_empty result
  end

  def test_type_key_is_hash_should_be_skipped
    hash = {"type" => {"nested" => "value"}, "item" => %w[x y]}
    result = extract_array_entries(hash, [])

    assert_equal %w[x y], result
  end

  def test_skips_type_even_if_hash_value
    hash = {"type" => {"complex" => "type"}, "data" => {"key" => "val"}}
    result = extract_array_entries(hash, [])

    assert_equal [{"key" => "val"}], result
  end

  def test_with_array_subclass
    subclass_array = ArraySubclass.new
    subclass_array.push("a", "b")
    hash = {"type" => "array", "items" => subclass_array}
    result = extract_array_entries(hash, [])

    assert_equal %w[a b], result
  end

  def test_with_hash_subclass_value
    subclass_hash = HashSubclass.new
    subclass_hash["key"] = "val"
    hash = {"type" => "array", "item" => subclass_hash}
    result = extract_array_entries(hash, [])

    assert_equal [{"key" => "val"}], result
  end

  def test_passes_disallowed_types
    hash = {"type" => "array", "item" => [{"type" => "yaml", "__content__" => "test"}]}

    assert_raises(MultiXml::DisallowedTypeError) do
      extract_array_entries(hash, ["yaml"])
    end
  end

  def test_passes_disallowed_types_for_hash
    hash = {"type" => "array", "item" => {"type" => "yaml", "__content__" => "test"}}

    assert_raises(MultiXml::DisallowedTypeError) do
      extract_array_entries(hash, ["yaml"])
    end
  end

  def test_hash_branch_uses_custom_disallowed_types_not_default
    # Use "integer" which is NOT in DISALLOWED_TYPES default, so if the mutant
    # removes the disallowed_types argument, it will use the default and NOT raise
    hash = {"type" => "array", "item" => {"type" => "integer", "__content__" => "42"}}

    assert_raises(MultiXml::DisallowedTypeError) do
      extract_array_entries(hash, ["integer"])
    end
  end

  def test_with_integer_value_returns_empty
    hash = {"type" => "array", "count" => 42}
    result = extract_array_entries(hash, [])

    assert_empty result
  end

  def test_with_nil_value_returns_empty
    hash = {"type" => "array", "items" => nil}
    result = extract_array_entries(hash, [])

    assert_empty result
  end

  def test_maps_entries_with_typecast
    hash = {"type" => "array", "item" => [{"type" => "integer", "__content__" => "42"}]}
    result = extract_array_entries(hash, [])

    assert_equal [42], result
  end

  def test_requires_array_or_hash_value
    hash = {"type" => "array", "name" => "string_value", "items" => %w[a b]}
    result = extract_array_entries(hash, [])

    assert_equal %w[a b], result
  end

  def test_with_frozen_type_key
    hash = {"type" => "array", "items" => %w[a b]}
    result = extract_array_entries(hash, [])

    assert_equal %w[a b], result
  end

  def test_skips_type_key_with_interned_string
    type_key = +"type"
    hash = {type_key => "array", "data" => %w[x y]}
    result = extract_array_entries(hash, [])

    assert_equal %w[x y], result
  end

  def test_with_custom_disallowed_type_raises
    hash = {"type" => "array", "item" => [{"type" => "integer", "__content__" => "42"}]}

    assert_raises(MultiXml::DisallowedTypeError) do
      extract_array_entries(hash, ["integer"])
    end
  end
end

# Tests disallowed_type? checking
class DisallowedTypeTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_returns_true_for_disallowed
    assert disallowed_type?("yaml", %w[yaml symbol])
  end

  def test_returns_false_for_allowed
    refute disallowed_type?("string", %w[yaml symbol])
  end

  def test_returns_false_for_nil_type
    refute disallowed_type?(nil, %w[yaml symbol])
  end

  def test_returns_false_when_type_is_hash
    refute disallowed_type?({"nested" => "value"}, ["yaml"])
  end

  def test_nil_type_returns_false
    refute disallowed_type?(nil, [nil])
  end

  def test_hash_type_not_checked
    hash_type = {"yaml" => true}

    refute disallowed_type?(hash_type, [hash_type])
  end

  def test_both_conditions_needed
    assert disallowed_type?("yaml", ["yaml"])
    refute disallowed_type?(nil, ["yaml"])
    refute disallowed_type?({"yaml" => true}, ["yaml"])
  end

  def test_with_hash_subclass
    subclass = HashSubclass.new
    subclass["yaml"] = true

    refute disallowed_type?(subclass, [subclass])
  end

  def test_checks_first_condition_type_truthiness
    refute disallowed_type?(false, ["false"])
  end

  def test_with_symbol_in_list
    assert disallowed_type?(:symbol, [:symbol])
  end
end

# Tests empty_value? checking for nil/empty values
class EmptyValueTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_true_for_empty_hash
    assert empty_value?({}, nil)
  end

  def test_true_when_nil_equals_true
    assert empty_value?({"nil" => "true"}, nil)
  end

  def test_true_when_only_type_present
    assert empty_value?({"type" => "integer"}, "integer")
  end

  def test_false_when_nil_not_true
    refute empty_value?({"nil" => "false", "other" => "value"}, nil)
  end

  def test_false_when_type_is_hash
    refute empty_value?({"type" => {"nested" => "value"}}, {"nested" => "value"})
  end

  def test_with_hash_type_returns_false
    hash_type = {"nested" => "data"}
    result = empty_value?({"type" => hash_type}, hash_type)

    refute result
  end

  def test_with_string_type_and_size_one
    result = empty_value?({"type" => "integer"}, "integer")

    assert result
  end

  def test_with_string_type_and_size_two
    result = empty_value?({"type" => "integer", "other" => "key"}, "integer")

    refute result
  end

  def test_with_hash_subclass_as_type
    type = HashSubclass.new
    type["nested"] = "value"
    hash = {"type" => type}

    refute empty_value?(hash, type)
  end

  def test_false_when_type_nil_and_hash_has_content
    refute empty_value?({"content" => "value"}, nil)
  end
end

# Tests convert_hash behavior for various type attributes
class ConvertHashTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_returns_empty_string_for_string_type_without_nil_true
    assert_equal "", convert_hash({"type" => "string"}, "string", [])
  end

  def test_returns_nil_for_string_type_with_nil_true
    assert_nil convert_hash({"type" => "string", "nil" => "true"}, "string", [])
  end

  def test_string_type_returns_empty_when_nil_absent
    hash = {"type" => "string"}
    result = convert_hash(hash, "string", [])

    assert_equal "", result
  end

  def test_string_type_returns_nil_when_nil_true
    hash = {"type" => "string", "nil" => "true"}
    result = convert_hash(hash, "string", [])

    assert_nil result
  end

  def test_string_type_returns_empty_when_nil_not_true
    hash = {"type" => "string", "nil" => "false"}
    result = convert_hash(hash, "string", [])

    assert_equal "", result
  end

  def test_with_array_type
    hash = {"type" => "array", "item" => %w[a b]}
    result = convert_hash(hash, "array", [])

    assert_equal %w[a b], result
  end

  def test_with_text_content
    hash = {"type" => "string", "__content__" => "hello"}
    result = convert_hash(hash, "string", [])

    assert_equal "hello", result
  end

  def test_returns_nil_for_empty_hash
    result = convert_hash({}, nil, [])

    assert_nil result
  end

  def test_typecasts_children_otherwise
    hash = {"child" => {"type" => "integer", "__content__" => "123"}}
    result = convert_hash(hash, nil, [])

    assert_equal({"child" => 123}, result)
  end

  def test_passes_disallowed_types_to_typecast_children
    hash = {"child" => {"type" => "yaml", "__content__" => "test"}}

    assert_raises(MultiXml::DisallowedTypeError) do
      convert_hash(hash, nil, ["yaml"])
    end
  end

  def test_passes_disallowed_types_to_extract_array
    hash = {"type" => "array", "item" => [{"type" => "yaml", "__content__" => "test"}]}

    assert_raises(MultiXml::DisallowedTypeError) do
      convert_hash(hash, "array", ["yaml"])
    end
  end

  def test_with_text_content_key_uses_convert_text_content
    hash = {MultiXml::TEXT_CONTENT_KEY => "42", "type" => "integer"}
    result = convert_hash(hash, "integer", [])

    assert_equal 42, result
  end

  def test_without_text_content_key_falls_through
    hash = {"type" => "string", "nil" => "false"}
    result = convert_hash(hash, "string", [])

    assert_equal "", result
  end

  def test_processes_non_array_non_text_content
    hash = {"child" => "value"}
    result = convert_hash(hash, nil, [])

    assert_equal({"child" => "value"}, result)
  end

  def test_integer_type_returns_nil_not_empty_string
    hash = {"type" => "integer"}
    result = convert_hash(hash, "integer", [])

    assert_nil result
  end

  def test_non_string_type_does_not_return_empty
    hash = {"type" => "boolean", "nil" => "false"}
    result = convert_hash(hash, "boolean", [])

    refute_equal "", result
    assert_kind_of Hash, result
  end

  def test_nil_check_uses_string_comparison
    hash = {"type" => "string", "nil" => "true"}
    result = convert_hash(hash, "string", [])

    assert_nil result
  end

  def test_empty_value_receives_type
    hash = {"type" => "integer"}
    result = convert_hash(hash, "integer", [])

    assert_nil result
  end

  def test_empty_value_type_matters
    hash = {"key" => "value"}
    result_with_nil_type = convert_hash(hash, nil, [])

    assert_equal({"key" => "value"}, result_with_nil_type)
  end

  def test_calls_typecast_children_last
    hash = {"name" => {"type" => "integer", "__content__" => "123"}}
    result = convert_hash(hash, nil, [])

    assert_equal({"name" => 123}, result)
  end

  def test_passes_disallowed_types_through_all_paths
    hash = {"nested" => {"type" => "symbol", "__content__" => "test"}}

    assert_raises(MultiXml::DisallowedTypeError) do
      convert_hash(hash, nil, ["symbol"])
    end
  end
end

# Tests convert_text_content with type converters
class ConvertTextContentTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_requires_content_key
    hash = {MultiXml::TEXT_CONTENT_KEY => "test value", "type" => "string"}
    result = convert_text_content(hash)

    assert_equal "test value", result
  end

  def test_accesses_content_key
    hash = {MultiXml::TEXT_CONTENT_KEY => "value", "type" => "string"}
    result = convert_text_content(hash)

    assert_equal "value", result
  end

  def test_with_unknown_type
    hash = {MultiXml::TEXT_CONTENT_KEY => "test value", "type" => "unknown_type"}
    result = convert_text_content(hash)

    assert_equal({"__content__" => "test value", "type" => "unknown_type"}, result)
  end

  def test_without_type_returns_content
    hash = {MultiXml::TEXT_CONTENT_KEY => "test value"}
    result = convert_text_content(hash)

    assert_equal "test value", result
  end
end

# Tests unwrap_if_simple value merging behavior
class UnwrapIfSimpleTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_merges_value_when_multiple_keys
    hash = {"attr1" => "val1", "attr2" => "val2"}
    value = "converted"
    result = unwrap_if_simple(hash, value)

    assert_equal({"attr1" => "val1", "attr2" => "val2", MultiXml::TEXT_CONTENT_KEY => "converted"}, result)
    assert_equal "converted", result[MultiXml::TEXT_CONTENT_KEY]
  end

  def test_returns_value_when_single_key
    hash = {"only_key" => "val"}
    value = "the_value"
    result = unwrap_if_simple(hash, value)

    assert_equal "the_value", result
  end

  def test_value_must_be_in_result
    hash = {"type" => "string", "other" => "data"}
    value = "important_content"
    result = unwrap_if_simple(hash, value)

    assert_includes result.keys, MultiXml::TEXT_CONTENT_KEY
    assert_equal "important_content", result[MultiXml::TEXT_CONTENT_KEY]
  end
end

# Tests typecast_hash type attribute handling
class TypecastHashTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_raises_disallowed_type_error_with_type
    error = assert_raises(MultiXml::DisallowedTypeError) do
      typecast_hash({"type" => "yaml"}, ["yaml"])
    end

    assert_equal "yaml", error.type
  end

  def test_passes_type_to_convert_hash
    hash = {"type" => "array", "item" => %w[a b c]}
    result = typecast_hash(hash, [])

    assert_equal %w[a b c], result
  end

  def test_type_affects_conversion
    hash = {"type" => "string", "nil" => "false"}
    result = typecast_hash(hash, [])

    assert_equal "", result
  end
end

# Tests key transformation helpers
class KeyTransformTest < Minitest::Test
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

# Tests raise_no_parser_error message formatting
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

  def test_no_parser_error_message_has_no_trailing_newline
    error = assert_raises(MultiXml::NoParserError) do
      MultiXml.send(:raise_no_parser_error)
    end

    refute error.message.end_with?("\n"), "Message should not end with newline"
  end
end

# Tests MultiXml.parse with options
class ParseMethodTest < Minitest::Test
  cover "MultiXml*"

  def setup
    @original_parser = MultiXml.instance_variable_get(:@parser)
    MultiXml.parser = :ox
  end

  def teardown
    if @original_parser
      MultiXml.instance_variable_set(:@parser, @original_parser)
    elsif MultiXml.instance_variable_defined?(:@parser)
      MultiXml.send(:remove_instance_variable, :@parser)
    end
  end

  def test_options_merge_preserves_parser
    MultiXml.parser = :rexml
    result = MultiXml.parse("<r>a</r>", parser: :ox)

    assert_equal({"r" => "a"}, result)
  end

  def test_options_merge_uses_defaults
    MultiXml.parser = :ox
    result = MultiXml.parse('<r type="integer">1</r>')

    assert_equal 1, result["r"]
  end

  def test_with_options_hash_merges_defaults
    result = MultiXml.parse("<root/>", {})

    assert_equal({"root" => nil}, result)
  end

  def test_applies_typecast_option
    result = MultiXml.parse('<n type="integer">5</n>', typecast_xml_value: true)

    assert_equal 5, result["n"]
  end

  def test_skips_typecast_when_disabled
    result = MultiXml.parse('<n type="integer">5</n>', typecast_xml_value: false)

    assert_equal({"type" => "integer", "__content__" => "5"}, result["n"])
  end

  def test_applies_symbolize_keys
    result = MultiXml.parse("<root><name>test</name></root>", symbolize_keys: true)

    assert_equal({root: {name: "test"}}, result)
  end

  def test_respects_disallowed_types_option
    assert_raises(MultiXml::DisallowedTypeError) do
      MultiXml.parse('<n type="yaml">test</n>', disallowed_types: ["yaml"])
    end
  end
end
