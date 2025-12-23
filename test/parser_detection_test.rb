require "test_helper"

# Shared setup/teardown for tests that modify MultiXml parser state
module ParserStateReset
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
end

# Tests for find_loaded_parser method
class FindLoadedParserTest < Minitest::Test
  cover "MultiXml*"
  include ParserStateReset

  def test_returns_best_available_parser_when_defined
    assert_equal best_available_parser, MultiXml.send(:find_loaded_parser)
  end

  def test_returns_nokogiri_when_ox_and_libxml_not_defined
    with_hidden_consts(:Ox, :LibXML) { assert_equal :nokogiri, MultiXml.send(:find_loaded_parser) }
  end

  def test_returns_oga_when_only_oga_defined
    with_hidden_consts(:Ox, :LibXML, :Nokogiri) { assert_equal :oga, MultiXml.send(:find_loaded_parser) }
  end

  def test_returns_nil_when_no_parsers_defined
    with_hidden_consts(:Ox, :LibXML, :Nokogiri, :Oga) { assert_nil MultiXml.send(:find_loaded_parser) }
  end

  private

  def with_hidden_consts(*const_names)
    # Only hide constants that are actually defined
    existing = const_names.select { |name| Object.const_defined?(name) }
    saved = existing.to_h { |name| [name, Object.send(:remove_const, name)] }
    MultiXml.send(:remove_instance_variable, :@parser) if MultiXml.instance_variable_defined?(:@parser)
    yield
  ensure
    saved&.each { |name, value| Object.const_set(name, value) }
  end
end

# Tests for find_available_parser method
class FindAvailableParserTest < Minitest::Test
  cover "MultiXml*"

  def test_returns_symbol
    assert_kind_of Symbol, MultiXml.send(:find_available_parser)
  end

  def test_returns_first_loadable_parser
    assert_equal best_available_parser, MultiXml.send(:find_available_parser)
  end

  def test_returns_nil_when_no_parsers_available
    with_parser_preference([["nonexistent_1", :fake1], ["nonexistent_2", :fake2]]) do
      assert_nil MultiXml.send(:find_available_parser)
    end
  end

  def test_continues_after_load_error
    # Use nokogiri as fallback since it's available on all platforms
    with_parser_preference([["nonexistent_parser_gem", :nonexistent], ["nokogiri", :nokogiri]]) do
      assert_equal :nokogiri, MultiXml.send(:find_available_parser)
    end
  end

  private

  def with_parser_preference(preference)
    original = MultiXml::PARSER_PREFERENCE.dup
    MultiXml.send(:remove_const, :PARSER_PREFERENCE)
    MultiXml.const_set(:PARSER_PREFERENCE, preference)
    yield
  ensure
    MultiXml.send(:remove_const, :PARSER_PREFERENCE)
    MultiXml.const_set(:PARSER_PREFERENCE, original.freeze)
  end
end

# Tests for detect_parser method
class DetectParserTest < Minitest::Test
  cover "MultiXml*"
  include ParserStateReset

  def test_returns_loaded_parser_when_available
    assert_equal best_available_parser, MultiXml.send(:detect_parser)
  end

  def test_falls_back_to_find_available_when_loaded_returns_nil
    MultiXml.stub(:find_loaded_parser, nil) do
      assert_equal best_available_parser, MultiXml.send(:detect_parser)
    end
  end

  def test_uses_find_loaded_result_not_find_available
    MultiXml.stub(:find_available_parser, :rexml) do
      assert_equal best_available_parser, MultiXml.send(:detect_parser)
    end
  end

  def test_raises_when_no_parser_available
    with_no_parsers_available do
      assert_raises(MultiXml::NoParserError) { MultiXml.send(:detect_parser) }
    end
  end

  private

  def with_no_parsers_available
    # Only remove constants that are actually defined
    existing = %i[Ox LibXML Nokogiri Oga].select { |n| Object.const_defined?(n) }
    saved_consts = existing.to_h { |n| [n, Object.send(:remove_const, n)] }
    saved_pref = MultiXml::PARSER_PREFERENCE
    MultiXml.send(:remove_const, :PARSER_PREFERENCE)
    MultiXml.const_set(:PARSER_PREFERENCE, [["nonexistent", :fake]])
    yield
  ensure
    saved_consts.each { |name, value| Object.const_set(name, value) }
    MultiXml.send(:remove_const, :PARSER_PREFERENCE)
    MultiXml.const_set(:PARSER_PREFERENCE, saved_pref)
  end
end

# Tests for raise_no_parser_error method
class RaiseNoParserErrorTest < Minitest::Test
  cover "MultiXml*"

  def test_raises_no_parser_error_with_helpful_message
    error = assert_raises(MultiXml::NoParserError) { MultiXml.send(:raise_no_parser_error) }
    assert_match(/No XML parser detected/, error.message)
    assert_match(/ox/, error.message)
  end
end
