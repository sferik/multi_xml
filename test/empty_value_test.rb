require "test_helper"
require_relative "test_subclasses"

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
