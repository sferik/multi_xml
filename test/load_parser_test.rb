require "test_helper"

# Tests for LoadParserTest
class LoadParserTest < Minitest::Test
  cover "MultiXML*"

  def test_load_parser_with_symbol
    result = MultiXML.send(:load_parser, :nokogiri)

    assert_equal MultiXML::Parsers::Nokogiri, result
  end

  def test_load_parser_with_string
    result = MultiXML.send(:load_parser, "nokogiri")

    assert_equal MultiXML::Parsers::Nokogiri, result
  end

  def test_load_parser_converts_to_string_and_downcases
    result = MultiXML.send(:load_parser, :NOKOGIRI)

    assert_equal MultiXML::Parsers::Nokogiri, result
  end
end

# Tests for LoadParserDetailedTest
class LoadParserDetailedTest < Minitest::Test
  cover "MultiXML*"

  def test_load_parser_downcases_symbol
    result = MultiXML.send(:load_parser, :NOKOGIRI)

    assert_equal MultiXML::Parsers::Nokogiri, result
  end

  def test_load_parser_converts_to_string
    result = MultiXML.send(:load_parser, "nokogiri")

    assert_equal MultiXML::Parsers::Nokogiri, result
  end
end

# Tests for LoadParserCamelizeTest
class LoadParserCamelizeTest < Minitest::Test
  cover "MultiXML*"

  def test_load_parser_converts_to_camelcase
    result = MultiXML.send(:load_parser, :NOKOGIRI)

    assert_equal MultiXML::Parsers::Nokogiri, result
  end

  def test_load_parser_handles_underscore_names
    skip "libxml not available on Windows/JRuby" if windows? || jruby?
    # libxml_sax should become LibxmlSax
    result = MultiXML.send(:load_parser, :libxml_sax)

    assert_equal MultiXML::Parsers::LibxmlSax, result
  end

  def test_load_parser_handles_underscore_names_nokogiri_sax
    # nokogiri_sax should become NokogiriSax
    result = MultiXML.send(:load_parser, :nokogiri_sax)

    assert_equal MultiXML::Parsers::NokogiriSax, result
  end
end

# Tests load_parser string conversion
class LoadParserStringConversionTest < Minitest::Test
  cover "MultiXML*"

  def test_load_parser_calls_to_s_on_symbol
    # Symbols don't have downcase method directly in older Ruby
    result = MultiXML.send(:load_parser, :NOKOGIRI)

    assert_equal MultiXML::Parsers::Nokogiri, result
  end

  def test_load_parser_calls_downcase
    # Without downcase, "NOKOGIRI" wouldn't match "nokogiri" file
    result = MultiXML.send(:load_parser, "NOKOGIRI")

    assert_equal MultiXML::Parsers::Nokogiri, result
  end

  def test_load_parser_with_mixed_case_string
    # Ensure downcase is called on the string
    result = MultiXML.send(:load_parser, "Nokogiri")

    assert_equal MultiXML::Parsers::Nokogiri, result
  end
end

# Tests that verify downcase is actually called on the require path
class LoadParserRequirePathTest < Minitest::Test
  cover "MultiXML*"

  def test_load_parser_requires_lowercase_path
    required_paths = []
    stub_require(required_paths) { MultiXML.send(:load_parser, "REXML") }

    assert_includes required_paths, "multi_xml/parsers/rexml"
  end

  private

  def stub_require(required_paths)
    original_require = Kernel.instance_method(:require)
    suppress_warnings { define_require(required_paths, original_require) }
    yield
  ensure
    suppress_warnings { restore_require(original_require) }
  end

  def define_require(required_paths, original_require)
    Kernel.define_method(:require) do |path|
      required_paths << path
      original_require.bind_call(self, path)
    end
  end

  def restore_require(original_require)
    Kernel.define_method(:require) { |path| original_require.bind_call(self, path) }
  end

  def suppress_warnings
    old_verbose = $VERBOSE
    $VERBOSE = nil
    yield
  ensure
    $VERBOSE = old_verbose
  end
end
