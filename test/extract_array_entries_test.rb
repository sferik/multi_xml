require "test_helper"
require_relative "test_subclasses"

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
end
