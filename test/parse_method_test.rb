require "test_helper"

# Tests MultiXml.parse with options
class ParseMethodTest < Minitest::Test
  cover "MultiXml*"

  def setup
    @original_parser = MultiXml.instance_variable_get(:@parser)
    MultiXml.parser = :ox
  end

  def teardown
    if @original_parser
      MultiXml.instance_variable_set(:@parser, @original_parser)
    elsif MultiXml.instance_variable_defined?(:@parser)
      MultiXml.send(:remove_instance_variable, :@parser)
    end
  end

  def test_options_merge_preserves_parser
    MultiXml.parser = :rexml
    result = MultiXml.parse("<r>a</r>", parser: :ox)

    assert_equal({"r" => "a"}, result)
  end

  def test_options_merge_uses_defaults
    MultiXml.parser = :ox
    result = MultiXml.parse('<r type="integer">1</r>')

    assert_equal 1, result["r"]
  end

  def test_with_options_hash_merges_defaults
    result = MultiXml.parse("<root/>", {})

    assert_equal({"root" => nil}, result)
  end

  def test_applies_typecast_option
    result = MultiXml.parse('<n type="integer">5</n>', typecast_xml_value: true)

    assert_equal 5, result["n"]
  end

  def test_skips_typecast_when_disabled
    result = MultiXml.parse('<n type="integer">5</n>', typecast_xml_value: false)

    assert_equal({"type" => "integer", "__content__" => "5"}, result["n"])
  end

  def test_applies_symbolize_keys
    result = MultiXml.parse("<root><name>test</name></root>", symbolize_keys: true)

    assert_equal({root: {name: "test"}}, result)
  end

  def test_respects_disallowed_types_option
    assert_raises(MultiXml::DisallowedTypeError) do
      MultiXml.parse('<n type="yaml">test</n>', disallowed_types: ["yaml"])
    end
  end
end
