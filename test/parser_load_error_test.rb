require "test_helper"

# Tests for MultiXML::ParserLoadError — raised when a parser can't be
# loaded, is missing from the filesystem, or doesn't satisfy the
# parser contract.
class ParserLoadErrorTest < Minitest::Test
  cover "MultiXML*"

  def test_inherits_from_argument_error
    assert_operator MultiXML::ParserLoadError, :<, ArgumentError
  end

  def test_stores_message
    error = MultiXML::ParserLoadError.new("oops")

    assert_equal "oops", error.message
  end

  def test_message_defaults_to_class_name
    error = MultiXML::ParserLoadError.new

    assert_equal "MultiXML::ParserLoadError", error.message
  end

  def test_build_wraps_original_exception_class_name_in_message
    original = LoadError.new("cannot load such file -- multi_xml/parsers/bogus")
    error = MultiXML::ParserLoadError.build(original)

    assert_kind_of MultiXML::ParserLoadError, error
    assert_match(/LoadError/, error.message)
    assert_match(/bogus/, error.message)
  end

  def test_build_copies_backtrace_from_cause
    original = LoadError.new("boom")
    original.set_backtrace(["trace/line:1"])
    error = MultiXML::ParserLoadError.build(original)

    assert_equal ["trace/line:1"], error.backtrace
  end

  def test_load_error_from_require_becomes_parser_load_error
    error = assert_raises(MultiXML::ParserLoadError) do
      MultiXML.send(:resolve_parser, :definitely_not_a_parser)
    end

    assert_match(/Did not recognize your parser specification/, error.message)
    assert_match(/LoadError:/, error.message)
  end

  def test_invalid_spec_type_raises_parser_load_error
    error = assert_raises(MultiXML::ParserLoadError) do
      MultiXML.send(:resolve_parser, 42)
    end

    assert_match(/expected parser to be a Symbol, String, or Module/, error.message)
  end

  def test_invalid_spec_message_inspects_the_spec
    # nil.to_s is "" but nil.inspect is "nil" — distinguishes spec.inspect
    # from plain interpolation.
    error = assert_raises(MultiXML::ParserLoadError) do
      MultiXML.send(:resolve_parser, nil)
    end

    assert_includes error.message, "nil"
  end

  def test_parser_without_parse_method_raises
    parser = Module.new
    error = assert_raises(MultiXML::ParserLoadError) do
      MultiXML.send(:resolve_parser, parser)
    end

    assert_match(/must respond to \.parse/, error.message)
    assert_includes error.message, parser.to_s
  end

  def test_parser_without_parse_error_contract_raises
    parser = Module.new do
      def self.parse(_io, **)
        {}
      end
    end

    error = assert_raises(MultiXML::ParserLoadError) do
      MultiXML.send(:resolve_parser, parser)
    end

    assert_match(/must define a ParseError constant or a \.parse_error method/, error.message)
    assert_includes error.message, parser.to_s
  end

  def test_parser_with_parse_error_method_passes_contract
    parser = Module.new do
      def self.parse(_io, **)
        {}
      end

      def self.parse_error
        StandardError
      end
    end

    assert_equal parser, MultiXML.send(:resolve_parser, parser)
  end

  def test_parser_with_parse_error_constant_passes_contract
    parser = Module.new do
      const_set(:ParseError, Class.new(StandardError))
      def self.parse(_io, **)
        {}
      end
    end

    assert_equal parser, MultiXML.send(:resolve_parser, parser)
  end
end
