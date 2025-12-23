require "test_helper"

# Tests for NormalizeInputTest
class NormalizeInputTest < Minitest::Test
  cover "MultiXml*"

  def test_normalize_input_returns_io_unchanged
    io = StringIO.new("<xml/>")

    result = MultiXml.send(:normalize_input, io)

    assert_same io, result
  end

  def test_normalize_input_converts_string_to_stringio
    result = MultiXml.send(:normalize_input, "<xml/>")

    assert_kind_of StringIO, result
    assert_equal "<xml/>", result.read
  end

  def test_normalize_input_strips_whitespace
    result = MultiXml.send(:normalize_input, "  <xml/>  ")

    assert_equal "<xml/>", result.read
  end

  def test_normalize_input_calls_to_s_on_non_string
    obj = Object.new
    def obj.to_s
      "<custom/>"
    end

    result = MultiXml.send(:normalize_input, obj)

    assert_equal "<custom/>", result.read
  end
end
