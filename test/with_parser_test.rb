require "test_helper"

# Tests for MultiXML.with_parser fiber-local scoped overrides
class WithParserTest < Minitest::Test
  cover "MultiXML*"

  def setup
    @original_parser = MultiXML.instance_variable_get(:@parser)
    Fiber[:multi_xml_parser] = nil
  end

  def teardown
    Fiber[:multi_xml_parser] = nil
    if @original_parser
      MultiXML.instance_variable_set(:@parser, @original_parser)
    elsif MultiXML.instance_variable_defined?(:@parser)
      MultiXML.send(:remove_instance_variable, :@parser)
    end
  end

  def test_swaps_parser_for_duration_of_block
    MultiXML.parser = :rexml

    inside = MultiXML.with_parser(:nokogiri) { MultiXML.parser }

    assert_equal "MultiXML::Parsers::Nokogiri", inside.name
  end

  def test_restores_previous_parser_after_block
    MultiXML.parser = :rexml

    MultiXML.with_parser(:nokogiri) { MultiXML.parse("<a>1</a>") }

    assert_equal "MultiXML::Parsers::Rexml", MultiXML.parser.name
  end

  def test_restores_parser_when_block_raises
    MultiXML.parser = :rexml

    assert_raises(StandardError) do
      MultiXML.with_parser(:nokogiri) { raise StandardError, "boom" }
    end
    assert_equal "MultiXML::Parsers::Rexml", MultiXML.parser.name
  end

  def test_returns_block_result
    result = MultiXML.with_parser(:rexml) { MultiXML.parse("<a>1</a>") }

    assert_equal({"a" => "1"}, result)
  end

  def test_accepts_module_spec
    require "multi_xml/parsers/nokogiri"

    inside = MultiXML.with_parser(MultiXML::Parsers::Nokogiri) { MultiXML.parser }

    assert_equal MultiXML::Parsers::Nokogiri, inside
  end

  def test_nested_with_parser_saves_and_restores
    MultiXML.parser = :rexml

    result = MultiXML.with_parser(:nokogiri) do
      MultiXML.with_parser(:rexml) { MultiXML.parser.name }
    end

    assert_equal "MultiXML::Parsers::Rexml", result
    assert_equal "MultiXML::Parsers::Rexml", MultiXML.parser.name
  end

  def test_nested_with_parser_restores_outer_override_not_process_default
    MultiXML.parser = :rexml

    outer_after_inner = MultiXML.with_parser(:nokogiri) do
      MultiXML.with_parser(:rexml) { nil }
      MultiXML.parser.name
    end

    assert_equal "MultiXML::Parsers::Nokogiri", outer_after_inner
  end

  def test_override_is_fiber_local
    MultiXML.parser = :rexml

    concurrent_parser = nil
    fiber = Fiber.new do
      concurrent_parser = MultiXML.parser.name
    end

    MultiXML.with_parser(:nokogiri) { fiber.resume }

    assert_equal "MultiXML::Parsers::Rexml", concurrent_parser
  end
end
