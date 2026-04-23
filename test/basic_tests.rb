# Tests fundamental parsing: empty input, valid XML, and CDATA handling
module ParserBasicTests
  def test_blank_string_returns_empty_hash
    assert_empty(MultiXML.parse(""))
  end

  def test_whitespace_string_returns_empty_hash
    assert_empty(MultiXML.parse(" "))
  end

  def test_frozen_whitespace_string_returns_empty_hash
    assert_empty(MultiXML.parse(" ".freeze))
  end

  def test_valid_xml_parses_correctly
    assert_equal({"user" => nil}, MultiXML.parse("<user/>"))
  end

  def test_cdata_returns_correct_content
    assert_equal "Erik Berlin", MultiXML.parse("<user><![CDATA[Erik Berlin]]></user>")["user"]
  end

  def test_xml_with_comment_ignores_comment_nodes
    assert_equal({"root" => "content"}, MultiXML.parse("<root><!-- comment -->content</root>"))
  end

  def test_xml_with_processing_instruction
    assert_equal({"root" => "content"}, MultiXML.parse('<?xml version="1.0"?><root>content</root>'))
  end
end

# Tests for parsers that properly raise errors on invalid XML (excludes Oga)
module ParserStrictErrorTests
  def test_invalid_xml_raises_parse_error
    assert_raises(MultiXML::ParseError) { MultiXML.parse("<open></close>") }
  end

  def test_invalid_xml_includes_original_xml_in_exception
    xml = "<open></close>"
    MultiXML.parse(xml)
  rescue MultiXML::ParseError => e
    assert_equal xml, e.xml
  end

  def test_invalid_xml_includes_underlying_cause_in_exception
    MultiXML.parse("<open></close>")
  rescue MultiXML::ParseError => e
    refute_nil e.cause
  end
end
