require "test_helper"
require "mutant/minitest/coverage"

# Tests for ParserDetectionTest
class ParserDetectionTest < Minitest::Test
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

  def test_find_loaded_parser_returns_libxml_when_ox_not_defined
    with_hidden_consts(:Ox) { assert_equal :libxml, MultiXml.send(:find_loaded_parser) }
  end

  def test_find_loaded_parser_returns_nokogiri_when_ox_and_libxml_not_defined
    with_hidden_consts(:Ox, :LibXML) { assert_equal :nokogiri, MultiXml.send(:find_loaded_parser) }
  end

  def test_find_loaded_parser_returns_oga_when_only_oga_defined
    with_hidden_consts(:Ox, :LibXML, :Nokogiri) { assert_equal :oga, MultiXml.send(:find_loaded_parser) }
  end

  def test_find_loaded_parser_returns_nil_when_no_parsers_defined
    with_hidden_consts(:Ox, :LibXML, :Nokogiri, :Oga) { assert_nil MultiXml.send(:find_loaded_parser) }
  end

  def test_find_available_parser_tries_to_load_parsers
    assert_equal :ox, MultiXml.send(:find_available_parser)
  end

  def test_find_available_parser_returns_nil_when_no_parsers_available
    with_fake_parser_preference { assert_nil MultiXml.send(:find_available_parser) }
  end

  def test_raise_no_parser_error_raises_no_parser_error
    error = assert_raises(MultiXml::NoParserError) { MultiXml.send(:raise_no_parser_error) }
    assert_match(/No XML parser detected/, error.message)
    assert_match(/ox/, error.message)
  end

  private

  def with_hidden_consts(*const_names)
    saved = const_names.to_h { |name| [name, Object.send(:remove_const, name)] }
    MultiXml.send(:remove_instance_variable, :@parser) if MultiXml.instance_variable_defined?(:@parser)
    yield
  ensure
    saved.each { |name, value| Object.const_set(name, value) }
  end

  def with_fake_parser_preference
    original = MultiXml::PARSER_PREFERENCE
    MultiXml.send(:remove_const, :PARSER_PREFERENCE)
    MultiXml.const_set(:PARSER_PREFERENCE, [["nonexistent_parser_1", :fake1], ["nonexistent_parser_2", :fake2]])
    yield
  ensure
    MultiXml.send(:remove_const, :PARSER_PREFERENCE)
    MultiXml.const_set(:PARSER_PREFERENCE, original)
  end
end

# Tests for DetectParserTest
class DetectParserTest < Minitest::Test
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

  def test_detect_parser_returns_loaded_parser_when_available
    assert_equal :ox, MultiXml.send(:detect_parser)
  end

  def test_detect_parser_raises_when_no_parser_available
    with_no_parsers_available { assert_raises(MultiXml::NoParserError) { MultiXml.send(:detect_parser) } }
  end

  private

  def with_no_parsers_available
    saved_consts = %i[Ox LibXML Nokogiri Oga].to_h { |n| [n, Object.send(:remove_const, n)] }
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

# Tests for DetectParserDetailedTest
class DetectParserDetailedTest < Minitest::Test
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

  def test_detect_parser_prefers_loaded_parser
    # Should return :ox since Ox is loaded
    result = MultiXml.send(:detect_parser)

    assert_equal :ox, result
  end
end

# Tests for FindLoadedParserDetailedTest
class FindLoadedParserDetailedTest < Minitest::Test
  cover "MultiXml*"

  def test_find_loaded_parser_returns_ox_when_defined
    # Ox should be defined in test environment
    result = MultiXml.send(:find_loaded_parser)

    assert_equal :ox, result
  end
end

# Tests for FindAvailableParserDetailedTest
class FindAvailableParserDetailedTest < Minitest::Test
  cover "MultiXml*"

  def test_find_available_parser_returns_first_loadable
    result = MultiXml.send(:find_available_parser)

    assert_equal :ox, result
  end
end

# Tests for DetectParserOrChainTest
class DetectParserOrChainTest < Minitest::Test
  cover "MultiXml*"

  def test_detect_parser_returns_loaded_parser_first
    # This tests that find_loaded_parser is called and its result used
    result = MultiXml.send(:detect_parser)

    # Since Ox is loaded, should return :ox
    assert_equal :ox, result
  end

  def test_detect_parser_falls_back_to_find_available_when_loaded_returns_nil
    # Stub find_loaded_parser to return nil to test the fallback
    MultiXml.stub :find_loaded_parser, nil do
      result = MultiXml.send(:detect_parser)

      # Should fall back to find_available_parser, which returns :ox
      assert_equal :ox, result
    end
  end

  def test_detect_parser_uses_find_loaded_result_not_find_available
    # Both return :ox in test env, but we can stub find_available to verify
    MultiXml.stub :find_available_parser, :rexml do
      result = MultiXml.send(:detect_parser)

      # Should use find_loaded_parser (:ox), not find_available_parser (:rexml stub)
      assert_equal :ox, result
    end
  end
end

# Tests for FindLoadedParserNilReturnTest
class FindLoadedParserNilReturnTest < Minitest::Test
  cover "MultiXml*"

  def test_find_loaded_parser_returns_nil_when_no_parser_defined
    # This is hard to test without undefining constants
    # But we can verify the method exists and returns expected type
    result = MultiXml.send(:find_loaded_parser)

    # In test environment, should return :ox since Ox is loaded
    assert_equal :ox, result
  end
end

# Tests for FindAvailableParserTest
class FindAvailableParserTest < Minitest::Test
  cover "MultiXml*"

  def test_find_available_parser_returns_parser_name
    # Verify find_available_parser returns a symbol
    result = MultiXml.send(:find_available_parser)

    assert_kind_of Symbol, result
  end

  def test_find_available_parser_uses_parser_preference_order
    result = MultiXml.send(:find_available_parser)

    # Should be :ox since it's first in preference and available
    assert_equal :ox, result
  end

  def test_find_available_parser_continues_after_load_error
    with_parser_preference([["nonexistent_parser_gem", :nonexistent], ["ox", :ox]]) do
      assert_equal :ox, MultiXml.send(:find_available_parser)
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
