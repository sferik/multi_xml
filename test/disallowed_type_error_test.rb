require "test_helper"
require "mutant/minitest/coverage"

# Tests for DisallowedTypeErrorTest
class DisallowedTypeErrorTest < Minitest::Test
  cover "MultiXml*"

  def test_stores_type
    error = MultiXml::DisallowedTypeError.new("yaml")

    assert_equal "yaml", error.type
  end

  def test_message_includes_type_inspect
    error = MultiXml::DisallowedTypeError.new("yaml")

    assert_equal 'Disallowed type attribute: "yaml"', error.message
  end

  def test_message_with_symbol_type
    error = MultiXml::DisallowedTypeError.new(:symbol)

    assert_equal "Disallowed type attribute: :symbol", error.message
  end

  def test_inherits_from_standard_error
    error = MultiXml::DisallowedTypeError.new("yaml")

    assert_kind_of StandardError, error
  end
end
