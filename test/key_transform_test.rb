require "test_helper"

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
