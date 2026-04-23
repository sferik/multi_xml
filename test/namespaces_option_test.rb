require "test_helper"

class RecordingNamespacesParser
  class << self
    attr_reader :calls, :last_namespaces

    def reset!
      @calls = 0
      @last_namespaces = :unset
    end

    def parse(_io, namespaces:)
      @calls += 1
      @last_namespaces = namespaces
      {"root" => {"my-key" => "value"}}
    end

    def parse_error
      StandardError
    end
  end
end

class LegacyNamespacesParser
  class << self
    attr_reader :calls, :last_io

    def reset!
      @calls = 0
      @last_io = nil
    end

    def parse(io)
      @calls += 1
      @last_io = io
      {"root" => {"legacy-key" => "value"}}
    end

    def parse_error
      StandardError
    end
  end
end

class KeyrestNamespacesParser
  class << self
    attr_reader :last_kwargs

    def reset!
      @last_kwargs = nil
    end

    def parse(_io, **kwargs)
      @last_kwargs = kwargs
      {"root" => "keyrest"}
    end

    def parse_error
      StandardError
    end
  end
end

class OptionalNamespacesParser
  class << self
    def parse(_io, namespaces: :strip)
      {"root" => namespaces.to_s}
    end

    def parse_error
      StandardError
    end
  end
end

class UnrelatedKeywordParser
  class << self
    def parse(_io, parser: nil)
      {"root" => parser.to_s}
    end

    def parse_error
      StandardError
    end
  end
end

class PositionalNamespacesParser
  class << self
    def parse(_io, namespaces)
      {"root" => namespaces.to_s}
    end

    def parse_error
      StandardError
    end
  end
end

class NamespacesOptionTest < Minitest::Test
  cover "MultiXML*"

  def setup
    @original_parser = MultiXML.instance_variable_get(:@parser)
    RecordingNamespacesParser.reset!
    LegacyNamespacesParser.reset!
    KeyrestNamespacesParser.reset!
  end

  def teardown
    if @original_parser
      MultiXML.instance_variable_set(:@parser, @original_parser)
    elsif MultiXML.instance_variable_defined?(:@parser)
      MultiXML.send(:remove_instance_variable, :@parser)
    end
  end

  def test_parse_passes_preserve_mode_through_without_undasherizing_keys
    result = MultiXML.parse("<root/>", parser: RecordingNamespacesParser, namespaces: :preserve, typecast_xml_value: false)

    assert_equal({"root" => {"my-key" => "value"}}, result)
    assert_equal :preserve, RecordingNamespacesParser.last_namespaces
    refute result.fetch("root").key?("my_key")
  end

  def test_parse_rejects_invalid_string_namespaces_mode_before_parser_runs
    error = assert_raises(ArgumentError) do
      MultiXML.parse("<root/>", parser: RecordingNamespacesParser, namespaces: "bogus", typecast_xml_value: false)
    end

    assert_equal 'invalid :namespaces mode "bogus"; expected one of [:strip, :preserve]', error.message
  end

  def test_parse_does_not_invoke_parser_for_invalid_string_namespaces_mode
    assert_raises(ArgumentError) do
      MultiXML.parse("<root/>", parser: RecordingNamespacesParser, namespaces: "bogus", typecast_xml_value: false)
    end

    assert_equal 0, RecordingNamespacesParser.calls
    assert_equal :unset, RecordingNamespacesParser.last_namespaces
  end

  def test_parse_rejects_invalid_namespaces_mode_for_empty_input
    error = assert_raises(ArgumentError) do
      MultiXML.parse("", namespaces: :bogus)
    end

    assert_equal "invalid :namespaces mode :bogus; expected one of [:strip, :preserve]", error.message
  end

  def test_parse_supports_legacy_custom_parser_without_namespaces_keyword
    result = MultiXML.parse("<root/>", parser: LegacyNamespacesParser, namespaces: :preserve, typecast_xml_value: false)

    assert_equal({"root" => {"legacy-key" => "value"}}, result)
    assert_equal 1, LegacyNamespacesParser.calls
  end

  def test_parse_with_namespaces_compatibility_passes_original_io_to_legacy_parser
    io = StringIO.new("<root/>")

    MultiXML.send(:parse_with_namespaces_compatibility, io, LegacyNamespacesParser, :preserve)

    assert_same io, LegacyNamespacesParser.last_io
  end

  def test_parse_with_namespaces_compatibility_passes_namespaces_to_keywordrest_parser
    io = StringIO.new("<root/>")

    MultiXML.send(:parse_with_namespaces_compatibility, io, KeyrestNamespacesParser, :preserve)

    assert_equal({namespaces: :preserve}, KeyrestNamespacesParser.last_kwargs)
  end

  def test_parser_supports_namespaces_keyword_detects_legacy_parser
    refute MultiXML.send(:parser_supports_namespaces_keyword?, LegacyNamespacesParser)
  end

  def test_parser_supports_namespaces_keyword_detects_optional_namespaces_keyword
    assert MultiXML.send(:parser_supports_namespaces_keyword?, OptionalNamespacesParser)
  end

  def test_parser_supports_namespaces_keyword_detects_keyrest
    assert MultiXML.send(:parser_supports_namespaces_keyword?, KeyrestNamespacesParser)
  end

  def test_parser_supports_namespaces_keyword_rejects_unrelated_keyword
    refute MultiXML.send(:parser_supports_namespaces_keyword?, UnrelatedKeywordParser)
  end

  def test_parser_supports_namespaces_keyword_rejects_positional_namespaces_argument
    refute MultiXML.send(:parser_supports_namespaces_keyword?, PositionalNamespacesParser)
  end
end
