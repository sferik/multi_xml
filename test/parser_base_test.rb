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
    # inherit: false ensures Parser#parse_error doesn't resolve to a
    # stray top-level ::ParseError (Racc defines one on MRI when
    # Nokogiri is loaded; not always present on JRuby). Stub one in
    # so the assertion holds on every platform.
    with_top_level_parse_error do
      parser = Module.new { extend MultiXML::Parser }

      assert_raises(MultiXML::ParserLoadError) { parser.parse_error }
    end
  end

  private

  def with_top_level_parse_error
    saved = Object.const_get(:ParseError) if Object.const_defined?(:ParseError, false)
    Object.send(:remove_const, :ParseError) if saved
    Object.const_set(:ParseError, Class.new(StandardError))
    yield
  ensure
    Object.send(:remove_const, :ParseError) if Object.const_defined?(:ParseError, false)
    Object.const_set(:ParseError, saved) if saved
  end
end
