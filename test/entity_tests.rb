# Tests XML entity decoding (&lt;, &gt;, etc.) and dash-to-underscore key conversion
module ParserEntityTests
  def test_xml_entities_in_content_are_unescaped
    {"<" => "&lt;", ">" => "&gt;", '"' => "&quot;", "'" => "&apos;", "&" => "&amp;"}.each do |char, entity|
      assert_equal char, MultiXml.parse("<tag>#{entity}</tag>")["tag"]
    end
  end

  def test_xml_entities_in_attribute_are_unescaped
    {"<" => "&lt;", ">" => "&gt;", '"' => "&quot;", "'" => "&apos;", "&" => "&amp;"}.each do |char, entity|
      assert_equal char, MultiXml.parse("<tag attribute=\"#{entity}\"/>")["tag"]["attribute"]
    end
  end

  def test_dasherized_tag_is_undasherized
    assert_includes MultiXml.parse("<tag-1/>").keys, "tag_1"
  end

  def test_dasherized_attribute_is_undasherized
    assert_includes MultiXml.parse('<tag attribute-1="1"></tag>')["tag"].keys, "attribute_1"
  end
end
