require "test_helper"

# Tests for DisallowedTypeErrorTest
class DisallowedTypeErrorTest < Minitest::Test
  cover "MultiXML*"

  def test_stores_type
    error = MultiXML::DisallowedTypeError.new("yaml")

    assert_equal "yaml", error.type
  end

  def test_message_includes_type_inspect
    error = MultiXML::DisallowedTypeError.new("yaml")

    assert_equal 'Disallowed type attribute: "yaml"', error.message
  end

  def test_message_with_symbol_type
    error = MultiXML::DisallowedTypeError.new(:symbol)

    assert_equal "Disallowed type attribute: :symbol", error.message
  end

  def test_inherits_from_standard_error
    error = MultiXML::DisallowedTypeError.new("yaml")

    assert_kind_of StandardError, error
  end
end
