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

class NamespacesOptionTest < Minitest::Test
  cover "MultiXml*"

  def setup
    @original_parser = MultiXml.instance_variable_get(:@parser)
    RecordingNamespacesParser.reset!
  end

  def teardown
    if @original_parser
      MultiXml.instance_variable_set(:@parser, @original_parser)
    elsif MultiXml.instance_variable_defined?(:@parser)
      MultiXml.send(:remove_instance_variable, :@parser)
    end
  end

  def test_parse_passes_preserve_mode_through_without_undasherizing_keys
    result = MultiXml.parse("<root/>", parser: RecordingNamespacesParser, namespaces: :preserve, typecast_xml_value: false)

    assert_equal({"root" => {"my-key" => "value"}}, result)
    assert_equal :preserve, RecordingNamespacesParser.last_namespaces
    refute result.fetch("root").key?("my_key")
  end

  def test_parse_rejects_invalid_string_namespaces_mode_before_parser_runs
    error = assert_raises(ArgumentError) do
      MultiXml.parse("<root/>", parser: RecordingNamespacesParser, namespaces: "bogus", typecast_xml_value: false)
    end

    assert_equal 'invalid :namespaces mode "bogus"; expected one of [:strip, :preserve]', error.message
  end

  def test_parse_does_not_invoke_parser_for_invalid_string_namespaces_mode
    assert_raises(ArgumentError) do
      MultiXml.parse("<root/>", parser: RecordingNamespacesParser, namespaces: "bogus", typecast_xml_value: false)
    end

    assert_equal 0, RecordingNamespacesParser.calls
    assert_equal :unset, RecordingNamespacesParser.last_namespaces
  end
end
