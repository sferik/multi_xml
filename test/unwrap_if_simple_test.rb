require "test_helper"

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
