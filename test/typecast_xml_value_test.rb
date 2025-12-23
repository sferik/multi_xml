require "test_helper"

# Tests typecast_xml_value with default and custom disallowed types
class TypecastXmlValueTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_uses_default_disallowed_types
    assert_raises(MultiXml::DisallowedTypeError) do
      typecast_xml_value({"type" => "yaml", "__content__" => "test"})
    end
  end

  def test_with_explicit_empty_disallowed_types
    result = typecast_xml_value({"type" => "yaml", "__content__" => "test"}, [])

    assert_equal "test", result
  end

  def test_passes_disallowed_types_to_array
    value = [{"type" => "yaml", "__content__" => "key: value"}, "second"]
    result = typecast_xml_value(value, [])

    assert_equal [{"key" => "value"}, "second"], result
  end

  def test_custom_disallowed_blocks_in_array
    value = [{"type" => "integer", "__content__" => "42"}]

    assert_raises(MultiXml::DisallowedTypeError) do
      typecast_xml_value(value, ["integer"])
    end
  end
end
