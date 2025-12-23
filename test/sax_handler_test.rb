require "test_helper"
require "multi_xml/parsers/sax_handler"

# Test harness that includes SaxHandler for testing
class SaxHandlerTestHarness
  include MultiXml::Parsers::SaxHandler

  def initialize
    initialize_handler
  end

  # Expose private method for testing
  def test_normalize_attrs(attrs)
    normalize_attrs(attrs)
  end
end

# Tests for SaxHandler normalize_attrs method
class SaxHandlerNormalizeAttrsTest < Minitest::Test
  cover "MultiXml*"

  def setup
    @handler = SaxHandlerTestHarness.new
  end

  def test_normalize_attrs_returns_hash_when_given_hash
    attrs = {"class" => "foo", "id" => "bar"}
    result = @handler.test_normalize_attrs(attrs)

    assert_equal attrs, result
    assert_same attrs, result # Should return the same object
  end

  def test_normalize_attrs_converts_array_to_hash
    attrs = [%w[class foo], %w[id bar]]
    result = @handler.test_normalize_attrs(attrs)

    assert_equal({"class" => "foo", "id" => "bar"}, result)
  end
end
