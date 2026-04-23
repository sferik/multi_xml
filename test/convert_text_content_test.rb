require "test_helper"

# Tests convert_text_content with type converters
class ConvertTextContentTest < Minitest::Test
  cover "MultiXML*"
  include MultiXML::Helpers

  def test_requires_content_key
    hash = {MultiXML::TEXT_CONTENT_KEY => "test value", "type" => "string"}
    result = convert_text_content(hash)

    assert_equal "test value", result
  end

  def test_accesses_content_key
    hash = {MultiXML::TEXT_CONTENT_KEY => "value", "type" => "string"}
    result = convert_text_content(hash)

    assert_equal "value", result
  end

  def test_with_unknown_type
    hash = {MultiXML::TEXT_CONTENT_KEY => "test value", "type" => "unknown_type"}
    result = convert_text_content(hash)

    assert_equal({"__content__" => "test value", "type" => "unknown_type"}, result)
  end

  def test_without_type_returns_content
    hash = {MultiXML::TEXT_CONTENT_KEY => "test value"}
    result = convert_text_content(hash)

    assert_equal "test value", result
  end
end
