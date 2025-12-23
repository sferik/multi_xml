require "test_helper"

# Tests for LoadParserTest
class LoadParserTest < Minitest::Test
  cover "MultiXml*"

  def test_load_parser_with_symbol
    result = MultiXml.send(:load_parser, :nokogiri)

    assert_equal MultiXml::Parsers::Nokogiri, result
  end

  def test_load_parser_with_string
    result = MultiXml.send(:load_parser, "nokogiri")

    assert_equal MultiXml::Parsers::Nokogiri, result
  end

  def test_load_parser_converts_to_string_and_downcases
    result = MultiXml.send(:load_parser, :NOKOGIRI)

    assert_equal MultiXml::Parsers::Nokogiri, result
  end
end

# Tests for LoadParserDetailedTest
class LoadParserDetailedTest < Minitest::Test
  cover "MultiXml*"

  def test_load_parser_downcases_symbol
    result = MultiXml.send(:load_parser, :OX)

    assert_equal MultiXml::Parsers::Ox, result
  end

  def test_load_parser_converts_to_string
    result = MultiXml.send(:load_parser, "ox")

    assert_equal MultiXml::Parsers::Ox, result
  end
end

# Tests for LoadParserCamelizeTest
class LoadParserCamelizeTest < Minitest::Test
  cover "MultiXml*"

  def test_load_parser_converts_to_camelcase
    result = MultiXml.send(:load_parser, :OX)

    assert_equal MultiXml::Parsers::Ox, result
  end

  def test_load_parser_handles_underscore_names
    # libxml_sax should become LibxmlSax
    result = MultiXml.send(:load_parser, :libxml_sax)

    assert_equal MultiXml::Parsers::LibxmlSax, result
  end
end

# Tests load_parser string conversion
class LoadParserStringConversionTest < Minitest::Test
  cover "MultiXml*"

  def test_load_parser_calls_to_s_on_symbol
    # Symbols don't have downcase method directly in older Ruby
    result = MultiXml.send(:load_parser, :OX)

    assert_equal MultiXml::Parsers::Ox, result
  end

  def test_load_parser_calls_downcase
    # Without downcase, "OX" wouldn't match "ox" file
    result = MultiXml.send(:load_parser, "OX")

    assert_equal MultiXml::Parsers::Ox, result
  end

  def test_load_parser_with_mixed_case_string
    # Ensure downcase is called on the string
    result = MultiXml.send(:load_parser, "Ox")

    assert_equal MultiXml::Parsers::Ox, result
  end
end

# Tests that verify downcase is actually called on the require path
class LoadParserRequirePathTest < Minitest::Test
  cover "MultiXml*"

  def test_load_parser_requires_lowercase_path
    # Track the actual require path used
    required_paths = []
    original_require = Kernel.instance_method(:require)

    Kernel.define_method(:require) do |path|
      required_paths << path
      original_require.bind_call(self, path)
    end

    MultiXml.send(:load_parser, "REXML")

    assert_includes required_paths, "multi_xml/parsers/rexml"
  ensure
    Kernel.define_method(:require) { |path| original_require.bind_call(self, path) }
  end
end
