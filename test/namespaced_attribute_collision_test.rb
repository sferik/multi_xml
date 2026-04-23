require "test_helper"
require "multi_xml/parsers/dom_parser"
require "multi_xml/parsers/rexml"
require "multi_xml/parsers/sax_handler"

begin
  require "multi_xml/parsers/libxml_sax"
rescue LoadError
  # libxml-ruby is not available on Windows / JRuby; tests that need it skip
end

begin
  require "multi_xml/parsers/ox"
rescue LoadError
  # ox is not available on Windows / JRuby; tests that need it skip
end

class DomParserCollisionHelper
  include MultiXML::Parsers::DomParser

  def each_child(_node)
  end

  def each_element_attr(_node)
  end

  def each_namespace_decl(_node)
  end

  def element_parts(_node)
    [nil, "root"]
  end

  def attr_parts(_attr)
    [nil, "id"]
  end
end

class SaxHandlerCollisionHelper
  include MultiXML::Parsers::SaxHandler

  def initialize
    initialize_handler(:strip)
  end

  def replace_current(value)
    @stack = [value]
  end

  def add(key, value)
    send(:add_attr_to_current, key, value)
  end

  def current_value
    @stack.last
  end
end

class NamespacedAttributeCollisionTest < Minitest::Test
  cover "MultiXML*"

  CHILD = {"__content__" => "child"}.freeze

  def test_dom_parser_add_attribute_value_appends_after_existing_attribute
    hash = {"id" => "111"}

    dom_parser_helper.send(:add_attribute_value, hash, "id", "222")

    assert_equal({"id" => %w[111 222]}, hash)
  end

  def test_dom_parser_add_attribute_value_inserts_before_child_hash
    hash = {"id" => CHILD}

    dom_parser_helper.send(:add_attribute_value, hash, "id", "111")

    assert_equal({"id" => ["111", CHILD]}, hash)
  end

  def test_dom_parser_add_attribute_value_inserts_before_child_hashes_in_existing_array
    hash = {"id" => ["111", CHILD]}

    dom_parser_helper.send(:add_attribute_value, hash, "id", "222")

    assert_equal({"id" => ["111", "222", CHILD]}, hash)
  end

  def test_sax_handler_add_attr_to_current_appends_after_existing_attribute
    sax_handler_helper.replace_current({"id" => "111"})

    sax_handler_helper.add("id", "222")

    assert_equal({"id" => %w[111 222]}, sax_handler_helper.current_value)
  end

  def test_sax_handler_add_attr_to_current_inserts_before_child_hash
    sax_handler_helper.replace_current({"id" => CHILD})

    sax_handler_helper.add("id", "111")

    assert_equal({"id" => ["111", CHILD]}, sax_handler_helper.current_value)
  end

  def test_sax_handler_add_attr_to_current_inserts_before_child_hashes_in_existing_array
    sax_handler_helper.replace_current({"id" => ["111", CHILD]})

    sax_handler_helper.add("id", "222")

    assert_equal({"id" => ["111", "222", CHILD]}, sax_handler_helper.current_value)
  end

  def test_libxml_sax_attribute_names_ignores_xmlns_declarations
    skip_unless_defined("libxml-ruby", MultiXML::Parsers.const_defined?(:LibxmlSax))
    tag = '<root xmlns:a="urn:a" xmlns="urn:root" a:id="111" id="222">'

    assert_equal %w[a:id id], MultiXML::Parsers::LibxmlSax.send(:attribute_names, tag)
  end

  def test_libxml_sax_detects_stripped_attribute_collision
    skip_unless_defined("libxml-ruby", MultiXML::Parsers.const_defined?(:LibxmlSax))
    xml = '<root xmlns:a="urn:a" xmlns:b="urn:b" a:id="111" b:id="222"/>'

    assert MultiXML::Parsers::LibxmlSax.send(:stripped_attribute_collision?, xml)
  end

  def test_libxml_sax_ignores_non_colliding_stripped_attributes
    skip_unless_defined("libxml-ruby", MultiXML::Parsers.const_defined?(:LibxmlSax))
    xml = '<root xmlns:a="urn:a" a:id="111" a:name="two"/>'

    refute MultiXML::Parsers::LibxmlSax.send(:stripped_attribute_collision?, xml)
  end

  def test_libxml_sax_parse_falls_back_to_dom_parser_for_stripped_attribute_collisions
    skip_unless_defined("libxml-ruby", MultiXML::Parsers.const_defined?(:LibxmlSax))
    xml = '<root xmlns:a="urn:a" xmlns:b="urn:b" a:id="111" b:id="222"/>'
    expected = {"root" => {"id" => %w[111 222]}}

    MultiXML::Parsers::Libxml.stub(:parse, expected) do
      assert_equal expected, MultiXML::Parsers::LibxmlSax.parse(StringIO.new(xml), namespaces: :strip)
    end
  end

  def test_ox_handler_attr_appends_after_existing_attribute
    skip_unless_defined("ox", MultiXML::Parsers.const_defined?(:Ox))
    handler = MultiXML::Parsers::Ox::Handler.new(:strip)

    handler.start_element(:root)
    handler.attr("a:id", "111")
    handler.attr("b:id", "222")
    handler.end_element(:root)

    assert_equal({"root" => {"id" => %w[111 222]}}, handler.result)
  end

  def test_ox_handler_add_attribute_value_inserts_before_child_hash
    skip_unless_defined("ox", MultiXML::Parsers.const_defined?(:Ox))
    hash = {"id" => CHILD}
    handler = MultiXML::Parsers::Ox::Handler.new(:strip)

    handler.send(:add_attribute_value, hash, "id", "111")

    assert_equal({"id" => ["111", CHILD]}, hash)
  end

  def test_ox_handler_add_attribute_value_appends_with_existing_attribute_array
    skip_unless_defined("ox", MultiXML::Parsers.const_defined?(:Ox))
    hash = {"id" => ["111"]}
    handler = MultiXML::Parsers::Ox::Handler.new(:strip)

    handler.send(:add_attribute_value, hash, "id", "222")

    assert_equal({"id" => %w[111 222]}, hash)
  end

  def test_rexml_add_attribute_value_inserts_before_child_hash
    hash = {"id" => CHILD}

    MultiXML::Parsers::Rexml.send(:add_attribute_value, hash, "id", "111")

    assert_equal({"id" => ["111", CHILD]}, hash)
  end

  def test_rexml_add_attribute_value_appends_with_existing_attribute_array
    hash = {"id" => ["111"]}

    MultiXML::Parsers::Rexml.send(:add_attribute_value, hash, "id", "222")

    assert_equal({"id" => %w[111 222]}, hash)
  end

  private

  def skip_unless_defined(name, loaded)
    skip "#{name} not available on this platform" unless loaded
  end

  def dom_parser_helper
    @dom_parser_helper ||= DomParserCollisionHelper.new
  end

  def sax_handler_helper
    @sax_handler_helper ||= SaxHandlerCollisionHelper.new
  end
end
