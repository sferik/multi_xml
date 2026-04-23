require "test_helper"

# Tests MultiXML.parse with options
class ParseMethodTest < Minitest::Test
  cover "MultiXML*"

  def setup
    @original_parser = MultiXML.instance_variable_get(:@parser)
    MultiXML.parser = best_available_parser
  end

  def teardown
    if @original_parser
      MultiXML.instance_variable_set(:@parser, @original_parser)
    elsif MultiXML.instance_variable_defined?(:@parser)
      MultiXML.send(:remove_instance_variable, :@parser)
    end
  end

  def test_options_merge_preserves_parser
    MultiXML.parser = :rexml
    result = MultiXML.parse("<r>a</r>", parser: :nokogiri)

    assert_equal({"r" => "a"}, result)
  end

  def test_options_merge_uses_defaults
    MultiXML.parser = best_available_parser
    result = MultiXML.parse('<r type="integer">1</r>')

    assert_equal 1, result["r"]
  end

  def test_with_options_hash_merges_defaults
    result = MultiXML.parse("<root/>", {})

    assert_equal({"root" => nil}, result)
  end

  def test_applies_typecast_option
    result = MultiXML.parse('<n type="integer">5</n>', typecast_xml_value: true)

    assert_equal 5, result["n"]
  end

  def test_skips_typecast_when_disabled
    result = MultiXML.parse('<n type="integer">5</n>', typecast_xml_value: false)

    assert_equal({"type" => "integer", "__content__" => "5"}, result["n"])
  end

  def test_applies_symbolize_names
    result = MultiXML.parse("<root><name>test</name></root>", symbolize_names: true)

    assert_equal({root: {name: "test"}}, result)
  end

  def test_respects_disallowed_types_option
    assert_raises(MultiXML::DisallowedTypeError) do
      MultiXML.parse('<n type="yaml">test</n>', disallowed_types: ["yaml"])
    end
  end
end
