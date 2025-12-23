# Tests parsing from IO streams like pipes (not just strings)
module ParserStreamTests
  def test_duplexed_stream_parses_correctly
    rd, wr = IO.pipe
    Thread.new do
      "<user/>".each_char { |chunk| wr << chunk }
      wr.close
    end

    assert_equal({"user" => nil}, MultiXml.parse(rd))
  end
end

# Tests specific to SAX parsers that accept both String and IO input directly
module SaxParserTests
  def test_sax_parser_direct_string_input
    result = MultiXml.parser.parse("<root>content</root>")

    assert_equal({"root" => {"__content__" => "content"}}, result)
  end

  def test_sax_parser_direct_io_input
    result = MultiXml.parser.parse(StringIO.new("<root>content</root>"))

    assert_equal({"root" => {"__content__" => "content"}}, result)
  end

  def test_sax_parser_direct_empty_io_input
    result = MultiXml.parser.parse(StringIO.new(""))

    assert_empty(result)
  end
end
