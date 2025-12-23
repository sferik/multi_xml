require "test_helper"

# Tests convert_hash string type behavior
class ConvertHashStringTypeTest < Minitest::Test
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

  def test_nil_check_uses_string_comparison
    hash = {"type" => "string", "nil" => "true"}
    result = convert_hash(hash, "string", [])

    assert_nil result
  end

  def test_non_string_type_does_not_return_empty
    hash = {"type" => "boolean", "nil" => "false"}
    result = convert_hash(hash, "boolean", [])

    refute_equal "", result
    assert_kind_of Hash, result
  end
end
