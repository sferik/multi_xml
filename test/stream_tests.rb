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
