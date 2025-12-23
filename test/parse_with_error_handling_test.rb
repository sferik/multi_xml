require "test_helper"

# Tests for ParseWithErrorHandlingTest
class ParseWithErrorHandlingTest < Minitest::Test
  cover "MultiXml*"

  def setup
    @original_parser = MultiXml.instance_variable_get(:@parser)
  end

  def teardown
    if @original_parser
      MultiXml.instance_variable_set(:@parser, @original_parser)
    elsif MultiXml.instance_variable_defined?(:@parser)
      MultiXml.send(:remove_instance_variable, :@parser)
    end
  end

  def test_parse_with_io_input_captures_xml_in_error
    MultiXml.parser = :nokogiri
    io = StringIO.new("<open></close>")

    begin
      MultiXml.parse(io)
    rescue MultiXml::ParseError => e
      assert_equal "<open></close>", e.xml
    end
  end

  def test_parse_error_message_from_parser
    MultiXml.parser = :nokogiri

    begin
      MultiXml.parse("<open></close>")
    rescue MultiXml::ParseError => e
      refute_nil e.message
      refute_empty e.message
    end
  end

  def test_parse_error_cause_is_parser_error
    MultiXml.parser = :nokogiri

    begin
      MultiXml.parse("<open></close>")
    rescue MultiXml::ParseError => e
      assert_kind_of Exception, e.cause
    end
  end

  def test_parse_returns_empty_hash_when_parser_returns_nil
    MultiXml.parser = :ox
    result = MultiXml.parse("<root/>")

    assert_kind_of Hash, result
  end
end

# Tests for ParseWithErrorHandlingDetailedTest
class ParseWithErrorHandlingDetailedTest < Minitest::Test
  cover "MultiXml*"

  def setup
    @original_parser = MultiXml.instance_variable_get(:@parser)
    MultiXml.parser = :nokogiri
  end

  def teardown
    return unless @original_parser

    MultiXml.instance_variable_set(:@parser, @original_parser)
  end

  def test_parse_wraps_parser_error_with_xml
    io = StringIO.new("<bad></wrong>")

    begin
      MultiXml.parse(io)

      flunk "Expected ParseError"
    rescue MultiXml::ParseError => e
      assert_equal "<bad></wrong>", e.xml
    end
  end

  def test_parse_wraps_parser_error_with_message
    MultiXml.parse("<bad></wrong>")

    flunk "Expected ParseError"
  rescue MultiXml::ParseError => e
    refute_nil e.message
  end

  def test_parse_wraps_parser_error_with_cause
    MultiXml.parse("<bad></wrong>")

    flunk "Expected ParseError"
  rescue MultiXml::ParseError => e
    refute_nil e.cause
  end
end

# Tests for ParseWithErrorHandlingNilTest
class ParseWithErrorHandlingNilTest < Minitest::Test
  cover "MultiXml*"

  def setup
    @original_parser = MultiXml.instance_variable_get(:@parser)
  end

  def teardown
    return unless @original_parser

    MultiXml.instance_variable_set(:@parser, @original_parser)
  end

  def test_parse_with_error_handling_handles_nil_parser_result
    # When parser returns nil, should get empty hash not nil
    MultiXml.parser = :ox
    result = MultiXml.parse("<empty/>")

    # Result should be a hash, not nil
    assert_kind_of Hash, result
  end

  def test_parse_error_with_io_uses_rewind
    MultiXml.parser = :nokogiri
    io = StringIO.new("<bad></wrong>")

    begin
      MultiXml.parse(io)

      flunk "Expected ParseError"
    rescue MultiXml::ParseError => e
      # io should have been rewound and read
      assert_equal "<bad></wrong>", e.xml
    end
  end
end

# Create a mock parser that returns nil
class NilReturningParser
  def self.parse(_io)
    nil
  end

  def self.parse_error
    StandardError
  end
end

# Create a mock parser that always fails
class FailingParser
  class ParseFailed < StandardError; end

  def self.parse(_io)
    raise ParseFailed, "Parse failed"
  end

  def self.parse_error
    ParseFailed
  end
end

# Tests for ParseWithErrorHandlingNilReturnTest
class ParseWithErrorHandlingNilReturnTest < Minitest::Test
  cover "MultiXml*"

  def setup
    @original_parser = MultiXml.instance_variable_get(:@parser)
  end

  def teardown
    return unless @original_parser

    MultiXml.instance_variable_set(:@parser, @original_parser)
  end

  def test_parse_returns_empty_hash_when_parser_returns_nil
    # When parser returns nil, without || {} we'd get nil passed to undasherize_keys
    MultiXml.parser = NilReturningParser
    # Disable typecast to see raw result from parse_with_error_handling
    result = MultiXml.parse("<test/>", typecast_xml_value: false)

    # Must be empty hash, not nil
    assert_empty(result)
  end

  def test_parse_returns_empty_hash_not_nil_when_parser_returns_nil
    MultiXml.parser = NilReturningParser
    # Disable typecast to see raw result
    result = MultiXml.parse("<test/>", typecast_xml_value: false)

    # Specifically test it's {} not nil
    refute_nil result
    assert_empty result
  end

  def test_parse_error_uses_to_s_on_string_input
    # Strings respond to both, but we're testing the to_s path
    MultiXml.parser = FailingParser

    begin
      MultiXml.parse("<bad/>")

      flunk "Expected ParseError"
    rescue MultiXml::ParseError => e
      assert_equal "<bad/>", e.xml
    end
  end

  def test_parse_error_with_io_that_responds_to_read
    MultiXml.parser = FailingParser
    io = StringIO.new("<bad/>")

    begin
      MultiXml.parse(io)

      flunk "Expected ParseError"
    rescue MultiXml::ParseError => e
      assert_equal "<bad/>", e.xml
    end
  end

  def test_parse_error_rewinds_io_before_reading
    # The FailingParser raises an error during parse, so original_input
    # still needs to be readable for error message
    MultiXml.parser = :nokogiri
    io = StringIO.new("<bad></wrong>")

    begin
      MultiXml.parse(io)

      flunk "Expected ParseError"
    rescue MultiXml::ParseError => e
      # Should have rewound and read full content
      assert_equal "<bad></wrong>", e.xml
    end
  end
end

# Tests parse error message handling
class ParseWithErrorHandlingMessageTest < Minitest::Test
  cover "MultiXml*"

  def setup
    @original_parser = MultiXml.instance_variable_get(:@parser)
  end

  def teardown
    return unless @original_parser

    MultiXml.instance_variable_set(:@parser, @original_parser)
  end

  def test_parse_error_message_is_original_exception_message
    MultiXml.parser = FailingParser

    begin
      MultiXml.parse("<bad/>")

      flunk "Expected ParseError"
    rescue MultiXml::ParseError => e
      # Message must be the string "Parse failed", not nil or the exception object
      assert_equal "Parse failed", e.message
      assert_instance_of String, e.message
    end
  end

  def test_parse_error_message_is_not_exception_object_to_s
    # If e is passed instead of e.message, the message would be e.to_s
    # which includes class name like "#<FailingParser::ParseFailed..."
    MultiXml.parser = FailingParser

    begin
      MultiXml.parse("<bad/>")

      flunk "Expected ParseError"
    rescue MultiXml::ParseError => e
      # Should be exactly "Parse failed", not the exception's inspect/to_s
      refute_match(/FailingParser/, e.message)
      refute_match(/#</, e.message)
    end
  end
end

# Tests parse error to_s behavior
class ParseWithErrorHandlingToSTest < Minitest::Test
  cover "MultiXml*"

  def setup
    @original_parser = MultiXml.instance_variable_get(:@parser)
  end

  def teardown
    return unless @original_parser

    MultiXml.instance_variable_set(:@parser, @original_parser)
  end

  def test_parse_error_xml_uses_to_s_not_to_str
    obj = obj_with_to_s("<from_to_s/>", to_str: "<from_to_str/>")

    assert_equal "<from_to_s/>", parse_error_xml(obj)
  end

  def test_parse_error_xml_uses_to_s_not_raw_input
    obj = obj_with_to_s("<converted/>")

    assert_equal "<converted/>", parse_error_xml(obj)
    assert_instance_of String, parse_error_xml(obj)
  end

  private

  def obj_with_to_s(to_s_val, to_str: nil)
    obj = Object.new
    obj.define_singleton_method(:to_s) { to_s_val }
    obj.define_singleton_method(:to_str) { to_str } if to_str
    obj
  end

  def parse_error_xml(input)
    MultiXml.parser = FailingParser
    MultiXml.parse(input)

    flunk "Expected ParseError"
  rescue MultiXml::ParseError => e
    e.xml
  end
end
