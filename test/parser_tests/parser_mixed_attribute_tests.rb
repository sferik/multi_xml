# Tests elements with both type attributes and other attributes, including unrecognized types
module ParserMixedAttributeTests
  def test_children_with_unrecognized_type_attribute_tags_on_content_nodes_first_value
    xml = "<options><value type='USD'>123</value><value type='percent'>0.123</value><value currency='USD'>123</value></options>"
    values = MultiXml.parse(xml)["options"]["value"]

    assert_equal "123", values[0]["__content__"]
    assert_equal "USD", values[0]["type"]
  end

  def test_children_with_unrecognized_type_attribute_tags_on_content_nodes_second_value
    xml = "<options><value type='USD'>123</value><value type='percent'>0.123</value><value currency='USD'>123</value></options>"
    values = MultiXml.parse(xml)["options"]["value"]

    assert_equal "0.123", values[1]["__content__"]
    assert_equal "percent", values[1]["type"]
  end

  def test_children_with_unrecognized_type_attribute_tags_on_content_nodes_third_value
    xml = "<options><value type='USD'>123</value><value type='percent'>0.123</value><value currency='USD'>123</value></options>"
    values = MultiXml.parse(xml)["options"]["value"]

    assert_equal "123", values[2]["__content__"]
    assert_equal "USD", values[2]["currency"]
  end

  def test_children_mixing_attributes_and_non_attributes_first_value
    xml = "<options><value type='USD'>123</value><value type='percent'>0.123</value><value>123</value></options>"

    assert_equal "123", MultiXml.parse(xml)["options"]["value"][0]["__content__"]
    assert_equal "USD", MultiXml.parse(xml)["options"]["value"][0]["type"]
  end

  def test_children_mixing_attributes_and_non_attributes_second_value
    xml = "<options><value type='USD'>123</value><value type='percent'>0.123</value><value>123</value></options>"

    assert_equal "0.123", MultiXml.parse(xml)["options"]["value"][1]["__content__"]
    assert_equal "percent", MultiXml.parse(xml)["options"]["value"][1]["type"]
  end

  def test_children_mixing_attributes_and_non_attributes_third_value
    xml = "<options><value type='USD'>123</value><value type='percent'>0.123</value><value>123</value></options>"

    assert_equal "123", MultiXml.parse(xml)["options"]["value"][2]
  end

  def test_children_mixing_recognized_type_attribute_and_non_type_attributes
    xml = "<options><value number='USD' type='integer'>123</value></options>"
    result = MultiXml.parse(xml)["options"]["value"]

    assert_equal 123, result["__content__"]
    assert_equal "USD", result["number"]
  end

  def test_children_mixing_unrecognized_type_attribute_and_non_type_attributes
    xml = "<options><value number='USD' type='currency'>123</value></options>"
    result = MultiXml.parse(xml)["options"]["value"]

    assert_equal "123", result["__content__"]
    assert_equal "USD", result["number"]
    assert_equal "currency", result["type"]
  end
end
