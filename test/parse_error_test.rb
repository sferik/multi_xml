require "test_helper"

# Tests for ParseErrorTest
class ParseErrorTest < Minitest::Test
  cover "MultiXml*"

  def test_parse_error_stores_message
    error = MultiXml::ParseError.new("Test message")

    assert_equal "Test message", error.message
  end

  def test_parse_error_with_nil_message_has_default_message
    error = MultiXml::ParseError.new

    assert_equal "MultiXml::ParseError", error.message
  end

  def test_parse_error_stores_xml
    error = MultiXml::ParseError.new("msg", xml: "<bad>")

    assert_equal "<bad>", error.xml
  end

  def test_parse_error_stores_cause
    cause = StandardError.new("original")
    error = MultiXml::ParseError.new("msg", cause: cause)

    assert_equal cause, error.cause
  end

  def test_parse_error_xml_defaults_to_nil
    error = MultiXml::ParseError.new("msg")

    assert_nil error.xml
  end

  def test_parse_error_cause_defaults_to_nil
    error = MultiXml::ParseError.new("msg")

    assert_nil error.cause
  end

  def test_parse_error_with_all_parameters
    cause = StandardError.new("original")
    error = MultiXml::ParseError.new("Test", xml: "<xml/>", cause: cause)

    assert_equal "Test", error.message
    assert_equal "<xml/>", error.xml
    assert_equal cause, error.cause
  end

  def test_parse_error_inherits_from_standard_error
    error = MultiXml::ParseError.new("test")

    assert_kind_of StandardError, error
  end
end
