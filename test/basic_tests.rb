# Tests fundamental parsing: empty input, valid XML, and CDATA handling
module ParserBasicTests
  def test_blank_string_returns_empty_hash
    assert_empty(MultiXml.parse(""))
  end

  def test_whitespace_string_returns_empty_hash
    assert_empty(MultiXml.parse(" "))
  end

  def test_frozen_whitespace_string_returns_empty_hash
    assert_empty(MultiXml.parse(" ".freeze))
  end

  def test_valid_xml_parses_correctly
    assert_equal({"user" => nil}, MultiXml.parse("<user/>"))
  end

  def test_cdata_returns_correct_content
    assert_equal "Erik Berlin", MultiXml.parse("<user><![CDATA[Erik Berlin]]></user>")["user"]
  end

  def test_xml_with_comment_ignores_comment_nodes
    assert_equal({"root" => "content"}, MultiXml.parse("<root><!-- comment -->content</root>"))
  end

  def test_xml_with_processing_instruction
    assert_equal({"root" => "content"}, MultiXml.parse('<?xml version="1.0"?><root>content</root>'))
  end
end

# Tests for parsers that properly raise errors on invalid XML (excludes Oga)
module ParserStrictErrorTests
  def test_invalid_xml_raises_parse_error
    assert_raises(MultiXml::ParseError) { MultiXml.parse("<open></close>") }
  end

  def test_invalid_xml_includes_original_xml_in_exception
    xml = "<open></close>"
    MultiXml.parse(xml)
  rescue MultiXml::ParseError => e
    assert_equal xml, e.xml
  end

  def test_invalid_xml_includes_underlying_cause_in_exception
    MultiXml.parse("<open></close>")
  rescue MultiXml::ParseError => e
    refute_nil e.cause
  end
end
