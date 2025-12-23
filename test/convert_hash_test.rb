require "test_helper"

# Tests convert_hash behavior for various type attributes
class ConvertHashTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

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
