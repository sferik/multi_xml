# Tests nested element parsing, sibling arrays, and whitespace handling in hierarchies
module ParserChildrenTests
  def test_children_with_attributes_return_correct_values
    assert_equal "Erik Berlin", MultiXml.parse('<users><user name="Erik Berlin"/></users>')["users"]["user"]["name"]
  end

  def test_children_with_text_return_correct_values
    assert_equal "Erik Berlin", MultiXml.parse("<user><name>Erik Berlin</name></user>")["user"]["name"]
  end

  def test_children_with_unrecognized_type_attribute_passes_through
    assert_equal "admin", MultiXml.parse('<user type="admin"><name>Erik Berlin</name></user>')["user"]["type"]
  end

  def test_children_with_non_type_attribute_tags_on_content_nodes
    xml = "<options><value currency='USD'>123</value><value number='percent'>0.123</value></options>"
    values = MultiXml.parse(xml)["options"]["value"]

    assert_equal "123", values[0]["__content__"]
    assert_equal "USD", values[0]["currency"]
    assert_equal "0.123", values[1]["__content__"]
    assert_equal "percent", values[1]["number"]
  end

  def test_children_with_newlines_and_whitespace_parse_correctly
    assert_equal({"user" => {"name" => "Erik Berlin"}}, MultiXml.parse("<user>\n  <name>Erik Berlin</name>\n</user>"))
  end

  def test_nested_children_parse_correctly
    xml = '<users><user name="Erik Berlin"><status text="Hello"/></user></users>'
    expected = {"users" => {"user" => {"name" => "Erik Berlin", "status" => {"text" => "Hello"}}}}

    assert_equal expected, MultiXml.parse(xml)
  end

  def test_sibling_children_return_array
    assert_kind_of Array, MultiXml.parse("<users><user>Erik Berlin</user><user>Wynn Netherland</user></users>")["users"]["user"]
  end

  def test_sibling_children_parse_correctly
    xml = "<users><user>Erik Berlin</user><user>Wynn Netherland</user></users>"

    assert_equal({"users" => {"user" => ["Erik Berlin", "Wynn Netherland"]}}, MultiXml.parse(xml))
  end

  def test_element_with_children_and_mixed_text
    result = MultiXml.parse("<root><child>inner</child> text </root>")

    assert result.dig("root", "child")
  end
end
