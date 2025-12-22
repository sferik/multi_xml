require "test_helper"
require "mutant/minitest/coverage"

# Test with Hash subclass for is_a? vs instance_of?
class HashSubclass < Hash
end

class ArraySubclass < Array
end

# Tests for DisallowedTypeHashSubclassTest
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

# Tests for ExtractArrayEntriesEdgeCasesTest
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

    assert_empty result
  end

  def test_extract_with_integer_value_returns_empty
    hash = {"type" => "array", "count" => 42}
    result = extract_array_entries(hash, [])

    assert_empty result
  end

  def test_extract_with_nil_value_returns_empty
    hash = {"type" => "array", "items" => nil}
    result = extract_array_entries(hash, [])

    assert_empty result
  end
end

# Tests for EmptyValueEdgeCasesTest
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

# Tests for ConvertHashEdgeCasesTest
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

# Tests for TypecastChildrenEdgeCasesTest
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

# Tests for TypecastArrayEdgeCasesTest
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
    assert_empty result
  end
end
