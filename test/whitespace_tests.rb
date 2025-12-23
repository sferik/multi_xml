# Tests whitespace preservation in text content vs. stripping around child elements
module ParserWhitespaceTests
  def test_preserves_whitespace_when_no_children_or_attributes
    assert_equal " ", MultiXml.parse("<tag> </tag>")["tag"]
  end

  def test_preserves_multiple_spaces_when_no_children_or_attributes
    assert_equal "   ", MultiXml.parse("<tag>   </tag>")["tag"]
  end

  def test_preserves_newlines_and_tabs_when_no_children_or_attributes
    assert_equal "\n\t\n", MultiXml.parse("<tag>\n\t\n</tag>")["tag"]
  end

  def test_strips_whitespace_when_there_are_child_elements
    assert_equal({"child" => nil}, MultiXml.parse("<tag> <child/> </tag>")["tag"])
  end

  def test_strips_whitespace_when_there_are_attributes
    assert_equal({"attr" => "val"}, MultiXml.parse('<tag attr="val"> </tag>')["tag"])
  end

  def test_preserves_content_with_surrounding_whitespace
    assert_equal "  hello  ", MultiXml.parse("<tag>  hello  </tag>")["tag"]
  end
end
