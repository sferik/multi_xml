# Tests parsing XML attributes and handling conflicts between attributes and child elements
module ParserAttributeTests
  def test_element_with_same_inner_element_and_attribute_name_returns_array
    assert_equal %w[John Smith], MultiXml.parse("<user name='John'><name>Smith</name></user>")["user"]["name"]
  end

  def test_content_returns_correct_value
    assert_equal "Erik Berlin", MultiXml.parse("<user>Erik Berlin</user>")["user"]
  end

  def test_attribute_returns_correct_value
    assert_equal "Erik Berlin", MultiXml.parse('<user name="Erik Berlin"/>')["user"]["name"]
  end

  def test_multiple_attributes_return_correct_values
    result = MultiXml.parse('<user name="Erik Berlin" screen_name="sferik"/>')["user"]

    assert_equal "Erik Berlin", result["name"]
    assert_equal "sferik", result["screen_name"]
  end
end
