require "test_helper"

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
