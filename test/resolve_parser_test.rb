require "test_helper"
require "support/mock_decoder"

# Tests for ResolveParserTest
class ResolveParserTest < Minitest::Test
  cover "MultiXml*"

  def test_resolve_parser_with_module
    require "multi_xml/parsers/nokogiri"
    result = MultiXml.send(:resolve_parser, MultiXml::Parsers::Nokogiri)

    assert_equal MultiXml::Parsers::Nokogiri, result
  end

  def test_resolve_parser_with_class
    result = MultiXml.send(:resolve_parser, MockDecoder)

    assert_equal MockDecoder, result
  end

  def test_resolve_parser_raises_for_invalid_spec
    error = assert_raises(RuntimeError) do
      MultiXml.send(:resolve_parser, 123)
    end

    assert_match(/Invalid parser specification/, error.message)
  end
end

# Tests for ResolveParserDetailedTest
class ResolveParserDetailedTest < Minitest::Test
  cover "MultiXml*"

  def test_resolve_parser_accepts_module
    require "multi_xml/parsers/nokogiri"
    result = MultiXml.send(:resolve_parser, MultiXml::Parsers::Nokogiri)

    assert_equal MultiXml::Parsers::Nokogiri, result
  end

  def test_resolve_parser_accepts_class
    result = MultiXml.send(:resolve_parser, MockDecoder)

    assert_equal MockDecoder, result
  end

  def test_resolve_parser_raises_for_integer
    error = assert_raises(RuntimeError) do
      MultiXml.send(:resolve_parser, 123)
    end

    assert_match(/Invalid parser/, error.message)
  end

  def test_resolve_parser_raises_for_nil
    error = assert_raises(RuntimeError) do
      MultiXml.send(:resolve_parser, nil)
    end

    assert_match(/Invalid parser/, error.message)
  end
end

# Tests resolve_parser case statement branches
class ResolveParserCaseTest < Minitest::Test
  cover "MultiXml*"

  def test_resolve_parser_handles_string
    result = MultiXml.send(:resolve_parser, "nokogiri")

    assert_equal MultiXml::Parsers::Nokogiri, result
  end

  def test_resolve_parser_handles_symbol
    result = MultiXml.send(:resolve_parser, :nokogiri)

    assert_equal MultiXml::Parsers::Nokogiri, result
  end

  def test_resolve_parser_handles_module
    require "multi_xml/parsers/nokogiri"
    result = MultiXml.send(:resolve_parser, MultiXml::Parsers::Nokogiri)

    assert_equal MultiXml::Parsers::Nokogiri, result
  end

  def test_resolve_parser_handles_class
    result = MultiXml.send(:resolve_parser, MockDecoder)

    assert_equal MockDecoder, result
  end
end
