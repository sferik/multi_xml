require "test_helper"

# Tests for MultiXML::Parser — the mixin that reads the ParseError
# constant off a parser module.
class ParserBaseTest < Minitest::Test
  cover "MultiXML*"

  def test_parse_error_returns_parse_error_constant
    parser = Module.new do
      extend MultiXML::Parser

      const_set(:ParseError, Class.new(StandardError))
    end

    assert_equal parser.const_get(:ParseError), parser.parse_error
  end

  def test_parse_error_raises_when_constant_is_missing
    parser = Module.new { extend MultiXML::Parser }

    error = assert_raises(MultiXML::ParserLoadError) { parser.parse_error }
    assert_match(/must define a ParseError constant/, error.message)
    assert_includes error.message, parser.to_s
  end

  def test_parse_error_lookup_ignores_top_level_parse_error
    # Racc defines ::ParseError when Nokogiri is loaded; inherit: false
    # ensures Parser#parse_error raises ParserLoadError for a parser
    # without its own ParseError constant instead of returning the
    # stray top-level constant.
    require "nokogiri"

    assert Object.const_defined?(:ParseError), "Nokogiri should have loaded Racc's top-level ::ParseError"

    parser = Module.new { extend MultiXML::Parser }

    assert_raises(MultiXML::ParserLoadError) { parser.parse_error }
  end
end
