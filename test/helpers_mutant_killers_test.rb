require "test_helper"
require "mutant/minitest/coverage"

# Test with Hash subclass for is_a? vs instance_of?
class HashSubclass < Hash
end

class ArraySubclass < Array
end

# Tests for ExtractArrayEntriesKillMutantsTest
class ExtractArrayEntriesKillMutantsTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_extract_array_entries_type_key_is_array_should_be_skipped
    # This test kills the mutant that removes k != "type"
    # The type key has an Array value but should still be skipped
    # Use String.new to ensure different object identity than literal "type"
    type_key = +"type"
    hash = {type_key => %w[array nested], "item" => %w[a b]}
    result = extract_array_entries(hash, [])

    # Should use "item", not "type" (even though type value is an Array)
    assert_equal %w[a b], result
  end

  def test_extract_array_entries_type_key_is_only_array
    # Edge case: only "type" key has array, but should return empty
    type_key = +"type"
    hash = {type_key => %w[array stuff]}
    result = extract_array_entries(hash, [])

    # Should skip "type" key and find nothing
    assert_empty result
  end

  def test_extract_array_entries_type_key_is_hash_should_be_skipped
    # The type key has a Hash value but should still be skipped
    # Use String.new to ensure different object identity
    type_key = +"type"
    hash = {type_key => {"nested" => "value"}, "item" => %w[x y]}
    result = extract_array_entries(hash, [])

    # Should use "item", not "type"
    assert_equal %w[x y], result
  end

  def test_extract_skips_type_even_if_hash_value
    # Test that "type" key is skipped even when its value is a Hash
    type_key = +"type"
    hash = {type_key => {"complex" => "type"}, "data" => {"key" => "val"}}
    result = extract_array_entries(hash, [])

    # Should find "data" which is a Hash, wrapped in array
    assert_equal [{"key" => "val"}], result
  end
end

# Tests for DisallowedTypeKillMutantsTest
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

# Tests for EmptyValueKillMutantsTest
class EmptyValueKillMutantsTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_empty_value_with_hash_type_returns_false
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

# Tests for TypecastChildrenKillMutantsTest
class TypecastChildrenKillMutantsTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_typecast_children_stringio_subclass_is_unwrapped
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

# Tests for ConvertHashKillMutantsTest
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

# Tests for TypecastArrayKillMutantsTest
class TypecastArrayKillMutantsTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_typecast_array_mutates_original
    input = [{"type" => "integer", "__content__" => "42"}]
    original_first = input.first
    typecast_array(input, [])

    # map! modifies in place
    assert_equal 42, input.first
    refute_same original_first, input.first
  end
end

# Tests for ParseMethodKillMutantsTest
class ParseMethodKillMutantsTest < Minitest::Test
  cover "MultiXml*"

  def setup
    @original_parser = MultiXml.instance_variable_get(:@parser)
  end

  def teardown
    return unless @original_parser

    MultiXml.instance_variable_set(:@parser, @original_parser)
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

# Tests for ExtractArrayEntriesSubclassTest
class ExtractArrayEntriesSubclassTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_extract_array_entries_with_array_subclass
    subclass_array = ArraySubclass.new
    subclass_array.push("a", "b")
    hash = {"type" => "array", "items" => subclass_array}
    result = extract_array_entries(hash, [])

    # With is_a?, subclass should be found
    assert_equal %w[a b], result
  end

  def test_extract_array_entries_with_hash_subclass_value
    subclass_hash = HashSubclass.new
    subclass_hash["key"] = "val"
    hash = {"type" => "array", "item" => subclass_hash}
    result = extract_array_entries(hash, [])

    # With is_a?, subclass should be found and wrapped in array
    assert_equal [{"key" => "val"}], result
  end

  def test_extract_array_entries_passes_disallowed_types
    hash = {"type" => "array", "item" => [{"type" => "yaml", "__content__" => "test"}]}

    assert_raises(MultiXml::DisallowedTypeError) do
      extract_array_entries(hash, ["yaml"])
    end
  end

  def test_extract_array_entries_passes_disallowed_types_for_hash
    hash = {"type" => "array", "item" => {"type" => "yaml", "__content__" => "test"}}

    assert_raises(MultiXml::DisallowedTypeError) do
      extract_array_entries(hash, ["yaml"])
    end
  end
end

# Tests for TypecastArraySubclassTest
class TypecastArraySubclassTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_typecast_array_one_returns_false_for_empty
    result = typecast_array([], [])

    # [].one? is false
    assert_empty result
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

# Tests for ConvertHashSubclassTest
class ConvertHashSubclassTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_convert_hash_passes_disallowed_types_to_typecast_children
    hash = {"child" => {"type" => "yaml", "__content__" => "test"}}

    assert_raises(MultiXml::DisallowedTypeError) do
      convert_hash(hash, nil, ["yaml"])
    end
  end

  def test_convert_hash_passes_disallowed_types_to_extract_array
    hash = {"type" => "array", "item" => [{"type" => "yaml", "__content__" => "test"}]}

    assert_raises(MultiXml::DisallowedTypeError) do
      convert_hash(hash, "array", ["yaml"])
    end
  end
end

# Tests for ConvertTextContentSubclassTest
class ConvertTextContentSubclassTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_convert_text_content_accesses_content_key
    hash = {MultiXml::TEXT_CONTENT_KEY => "value", "type" => "string"}
    result = convert_text_content(hash)

    assert_equal "value", result
  end
end

# Tests for TypecastChildrenSubclassTest
class TypecastChildrenSubclassTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_typecast_children_accesses_file_key
    hash = {"name" => "test"}
    result = typecast_children(hash, [])

    # When "file" key doesn't exist, result["file"] returns nil
    # result.fetch("file") would raise KeyError
    assert_kind_of Hash, result
    assert_nil result["file"]
  end
end

# Tests for DisallowedTypeSubclassTest
class DisallowedTypeSubclassTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_disallowed_type_with_hash_subclass
    subclass = HashSubclass.new
    subclass["yaml"] = true

    # With is_a?, Hash subclass should also return false
    refute disallowed_type?(subclass, [subclass])
  end
end

# Tests for TypecastArrayFirstTest
class TypecastArrayFirstTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_typecast_array_returns_first_for_single_element
    result = typecast_array(["only_element"], [])

    assert_equal "only_element", result
  end
end

# Tests for ExtractArrayMapTest
class ExtractArrayMapTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_extract_array_maps_entries_with_typecast
    hash = {"type" => "array", "item" => [{"type" => "integer", "__content__" => "42"}]}
    result = extract_array_entries(hash, [])

    # Should have typecasted the integer
    assert_equal [42], result
  end
end

# Tests for ConvertHashTypecastChildrenTest
class ConvertHashTypecastChildrenTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_convert_hash_calls_typecast_children_last
    hash = {"name" => {"type" => "integer", "__content__" => "123"}}
    result = convert_hash(hash, nil, [])

    # Should have called typecast_children which typecasts nested values
    assert_equal({"name" => 123}, result)
  end
end

# Tests for TypecastArrayDisallowedTypesTest
class TypecastArrayDisallowedTypesTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_typecast_array_passes_disallowed_types_to_nested_calls
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

# Tests for TypecastChildrenFetchMutantTest
class TypecastChildrenFetchMutantTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_typecast_children_uses_bracket_access_for_file
    # fetch raises KeyError when key missing, [] returns nil
    hash = {"name" => "test", "data" => "value"}
    result = typecast_children(hash, [])

    # Should work even without "file" key
    assert_kind_of Hash, result
    assert_equal "test", result["name"]
  end
end

# Tests for ConvertTextContentFetchMutantTest
class ConvertTextContentFetchMutantTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_convert_text_content_uses_bracket_access
    # Both work the same when key exists
    hash = {MultiXml::TEXT_CONTENT_KEY => "value"}
    result = convert_text_content(hash)

    assert_equal "value", result
  end
end

# Tests for ExtractArrayEntriesStringComparisonTest
class ExtractArrayEntriesStringComparisonTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_extract_array_entries_with_frozen_type_key
    # equal? checks object identity, so frozen strings with same content are equal
    # but different string objects are not equal? even with same content
    hash = {"type" => "array", "items" => %w[a b]}
    result = extract_array_entries(hash, [])

    assert_equal %w[a b], result
  end

  def test_extract_array_entries_skips_type_key_with_interned_string
    # Use a string that might be interned differently
    type_key = +"type"
    hash = {type_key => "array", "data" => %w[x y]}
    result = extract_array_entries(hash, [])

    # Should skip the type key regardless of string identity
    assert_equal %w[x y], result
  end
end

# Tests for ConvertHashDisallowedTypesTest
class ConvertHashDisallowedTypesTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_convert_hash_passes_disallowed_types_through_all_paths
    hash = {"nested" => {"type" => "symbol", "__content__" => "test"}}

    assert_raises(MultiXml::DisallowedTypeError) do
      convert_hash(hash, nil, ["symbol"])
    end
  end
end

# Tests for ExtractArrayEntriesMapTest
class ExtractArrayEntriesMapTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_extract_array_entries_maps_with_typecast
    hash = {"type" => "array", "item" => [{"type" => "integer", "__content__" => "99"}]}
    result = extract_array_entries(hash, [])

    # Should have typecasted the nested value
    assert_equal [99], result
  end

  def test_extract_array_entries_passes_disallowed_to_map
    # Use empty disallowed_types to allow yaml - mutant would use default which disallows yaml
    hash = {"type" => "array", "item" => [{"type" => "yaml", "__content__" => "test"}]}
    result = extract_array_entries(hash, [])

    # With empty disallowed_types, yaml should be ALLOWED
    assert_equal ["test"], result
  end

  def test_extract_array_entries_passes_disallowed_to_hash_branch
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

# Tests for UnwrapIfSimpleMutantKillerTest
class UnwrapIfSimpleMutantKillerTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_unwrap_if_simple_merges_value_when_multiple_keys
    hash = {"attr1" => "val1", "attr2" => "val2"}
    value = "converted"
    result = unwrap_if_simple(hash, value)

    # Must merge the value with TEXT_CONTENT_KEY
    assert_equal({"attr1" => "val1", "attr2" => "val2", MultiXml::TEXT_CONTENT_KEY => "converted"}, result)
    assert_equal "converted", result[MultiXml::TEXT_CONTENT_KEY]
  end

  def test_unwrap_if_simple_returns_value_when_single_key
    hash = {"only_key" => "val"}
    value = "the_value"
    result = unwrap_if_simple(hash, value)

    assert_equal "the_value", result
  end

  def test_unwrap_if_simple_value_must_be_in_result
    hash = {"type" => "string", "other" => "data"}
    value = "important_content"
    result = unwrap_if_simple(hash, value)

    assert_includes result.keys, MultiXml::TEXT_CONTENT_KEY
    assert_equal "important_content", result[MultiXml::TEXT_CONTENT_KEY]
  end
end

# Tests for ConvertHashMutantKillerTest
class ConvertHashMutantKillerTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_convert_hash_with_text_content_key_uses_convert_text_content
    hash = {MultiXml::TEXT_CONTENT_KEY => "42", "type" => "integer"}
    result = convert_hash(hash, "integer", [])

    # Should call convert_text_content which converts integer
    assert_equal 42, result
  end

  def test_convert_hash_without_text_content_key_falls_through
    # When TEXT_CONTENT_KEY is absent, should not call convert_text_content
    hash = {"type" => "string", "nil" => "false"}
    result = convert_hash(hash, "string", [])

    # Should return empty string from string type handling
    assert_equal "", result
  end

  def test_convert_hash_processes_non_array_non_text_content
    # Test the path through typecast_children
    hash = {"child" => "value"}
    result = convert_hash(hash, nil, [])

    assert_equal({"child" => "value"}, result)
  end

  def test_convert_hash_string_type_returns_empty_not_typecast_children
    # Non-string types like "integer" should NOT return ""
    hash = {"type" => "integer"}
    result = convert_hash(hash, "integer", [])

    # type="integer" without TEXT_CONTENT_KEY should fall through to empty_value?
    # then return nil (empty hash with just type)
    assert_nil result
  end

  def test_convert_hash_non_string_type_does_not_return_empty
    # Another test to kill: type == "string" -> type
    # When type is something other than "string", should not return ""
    hash = {"type" => "boolean", "nil" => "false"}
    result = convert_hash(hash, "boolean", [])

    # type="boolean" should not trigger the return "" branch
    # It goes through typecast_children and returns the hash
    refute_equal "", result
    assert_kind_of Hash, result
  end

  def test_convert_hash_nil_check_uses_string_comparison
    # This tests that we're using != (value comparison) not eql? (which is same for strings)
    # Both should work identically for string comparison, so we verify the behavior
    hash = {"type" => "string", "nil" => "true"}
    result = convert_hash(hash, "string", [])

    # When nil="true", should NOT return ""
    assert_nil result
  end

  def test_convert_hash_empty_value_receives_type
    # When type is present and hash.size == 1, empty_value? should return true
    hash = {"type" => "integer"}
    result = convert_hash(hash, "integer", [])

    # empty_value? with type="integer" and hash.size==1 returns true, so result is nil
    assert_nil result
  end

  def test_convert_hash_empty_value_type_matters
    # Test where nil vs actual type makes a difference
    # empty_value? returns true when type && hash.size == 1 && !type.is_a?(Hash)
    hash = {"key" => "value"}
    result_with_nil_type = convert_hash(hash, nil, [])

    # With nil type, empty_value? check (type && ...) is false, so falls through to typecast_children
    assert_equal({"key" => "value"}, result_with_nil_type)
  end
end

# Tests for ConvertTextContentMutantKillerTest
class ConvertTextContentMutantKillerTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_convert_text_content_uses_bracket_access_not_fetch
    # Both work when key exists, but this verifies correct behavior
    hash = {MultiXml::TEXT_CONTENT_KEY => "test_value"}
    result = convert_text_content(hash)

    assert_equal "test_value", result
  end
end

# Tests for ExtractArrayEntriesConditionMutantTest
class ExtractArrayEntriesConditionMutantTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_extract_requires_array_or_hash_value
    # When entry has string value (not Array/Hash), should skip it
    hash = {"type" => "array", "name" => "string_value", "items" => %w[a b]}
    result = extract_array_entries(hash, [])

    # Should find "items" (Array), not "name" (String)
    assert_equal %w[a b], result
  end

  def test_extract_finds_first_array_or_hash
    # If the mutant changes to just k != "type", it would match the first non-type key
    hash = {"type" => "array", "string_val" => "ignored", "data" => [1, 2, 3]}
    result = extract_array_entries(hash, [])

    # Should skip string_val and find data
    assert_equal [1, 2, 3], result
  end

  def test_extract_array_is_a_check_for_array
    # When value is truthy but not Array/Hash, should skip
    hash = {"type" => "array", "count" => 42, "items" => %w[x y]}
    result = extract_array_entries(hash, [])

    # 42 is truthy but not an Array, should skip to "items"
    assert_equal %w[x y], result
  end

  def test_extract_array_is_a_check_for_hash
    hash = {"type" => "array", "count" => 5, "item" => {"key" => "val"}}
    result = extract_array_entries(hash, [])

    # Should find "item" which is a Hash
    assert_equal [{"key" => "val"}], result
  end

  def test_extract_equality_vs_eql_vs_equal
    # equal? uses object identity, so dynamically created strings would fail
    dynamic_type = +"type"
    hash = {dynamic_type => "array", "items" => %w[1 2]}
    result = extract_array_entries(hash, [])

    # With != or eql?, "type" matches; with equal?, it wouldn't
    assert_equal %w[1 2], result
  end

  def test_extract_type_key_skipped_with_different_string_object
    # equal? checks object identity - different string objects with same content
    # would NOT match with equal? but WOULD match with != or eql?
    # We need the "type" key to be a different object but same content
    type_key = +"type"

    refute_same type_key, "type" # Verify they're different objects

    hash = {type_key => "array", "data" => %w[x y z]}
    result = extract_array_entries(hash, [])

    # With !=, both string objects with content "type" are equal, so type key is skipped
    # With equal?, they would NOT match, so type key would be included (wrong behavior)
    assert_equal %w[x y z], result
  end

  def test_extract_uses_value_equality_not_identity_for_type
    # Create a hash where "type" key comes from string concatenation (new object)
    type_key = "type"
    # Force it to be a different object by modifying then restoring
    type_key = String.new(type_key)

    hash = {type_key => "array", "items" => [{"key" => "val"}]}
    result = extract_array_entries(hash, [])

    # "type" key should still be skipped even if it's a different string object
    assert_equal [{"key" => "val"}], result
  end
end

# Tests for TypecastChildrenMutantKillerTest
class TypecastChildrenMutantKillerTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_typecast_children_returns_file_not_fetches
    # In the return path, we want bracket access
    file = StringIO.new("content")
    hash = {"file" => file}
    result = typecast_children(hash, [])

    # Should return the file directly
    assert_same file, result
  end
end

# Tests for TypecastHashMutantKillerTest
class TypecastHashMutantKillerTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_typecast_hash_passes_type_to_convert_hash
    # The type must be passed to convert_hash for proper handling
    hash = {"type" => "array", "item" => %w[a b c]}
    result = typecast_hash(hash, [])

    # With type="array", should extract array entries
    # If type is nil, it would typecast_children instead
    assert_equal %w[a b c], result
  end

  def test_typecast_hash_type_affects_conversion
    # Another test to kill the type -> nil mutant
    hash = {"type" => "string", "nil" => "false"}
    result = typecast_hash(hash, [])

    # type="string" with nil != "true" returns ""
    # If type were nil, it would go through typecast_children path
    assert_equal "", result
  end
end

# Tests for TypecastXmlValueMutantKillerTest
class TypecastXmlValueMutantKillerTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_typecast_xml_value_passes_disallowed_types_to_array
    # Use empty disallowed_types to allow yaml
    # Use two elements since single element arrays are unwrapped
    value = [{"type" => "yaml", "__content__" => "key: value"}, "second"]
    result = typecast_xml_value(value, [])

    # With empty disallowed_types, yaml is allowed
    # If nil were passed, default DISALLOWED_TYPES would be used (blocks yaml)
    assert_equal [{"key" => "value"}, "second"], result
  end

  def test_typecast_xml_value_custom_disallowed_blocks_in_array
    # Verify that custom disallowed_types are actually passed
    value = [{"type" => "integer", "__content__" => "42"}]

    assert_raises(MultiXml::DisallowedTypeError) do
      typecast_xml_value(value, ["integer"])
    end
  end
end
