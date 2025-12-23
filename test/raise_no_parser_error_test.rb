require "test_helper"

# Tests raise_no_parser_error message formatting
class RaiseNoParserErrorTest < Minitest::Test
  cover "MultiXml*"

  def test_raises_no_parser_error_with_message
    error = assert_raises(MultiXml::NoParserError) do
      MultiXml.send(:raise_no_parser_error)
    end

    assert_includes error.message, "No XML parser detected"
  end

  def test_raises_no_parser_error_mentions_parser_options
    error = assert_raises(MultiXml::NoParserError) do
      MultiXml.send(:raise_no_parser_error)
    end

    assert_includes error.message, "ox"
    assert_includes error.message, "nokogiri"
  end

  def test_no_parser_error_message_has_no_trailing_newline
    error = assert_raises(MultiXml::NoParserError) do
      MultiXml.send(:raise_no_parser_error)
    end

    refute error.message.end_with?("\n"), "Message should not end with newline"
  end
end
