require "test_helper"

# Cross-parser test matrix for the :namespaces option (issue #44).
#
# Every parser backend must produce byte-identical output for the same
# input + mode combination.
#
# Modes:
#   :strip    (default) -- drop xmlns/xmlns:* attrs, drop prefixes from names
#   :preserve           -- keep xmlns/xmlns:* attrs, keep prefix:local verbatim
module NamespaceHandlingMatrix
  # ------------------------------------------------------------------
  # Fixtures
  # ------------------------------------------------------------------

  FEED_NS = "http://kosapi.feld.cvut.cz/schema/3".freeze
  ATOM_NS = "http://www.w3.org/2005/Atom".freeze
  OSEARCH_NS = "http://a9.com/-/spec/opensearch/1.1/".freeze

  # From https://gist.github.com/jnv/11763399bcfcead72a2c (the issue's gist),
  # trimmed to the discriminating parts. Exercises:
  #   * default namespace on the root
  #   * multiple prefixed namespace declarations
  #   * prefixed attribute on a non-prefixed element (link/@atom:rel)
  #   * prefixed element (osearch:startIndex)
  #   * xml:base / xml:lang (reserved xml prefix)
  FEED_XML = <<~XML.freeze
    <feed xmlns="http://kosapi.feld.cvut.cz/schema/3"
          xmlns:atom="http://www.w3.org/2005/Atom"
          xmlns:osearch="http://a9.com/-/spec/opensearch/1.1/"
          xml:base="https://kosapi.fit.cvut.cz/api/3"
          xml:lang="cs">
      <link atom:rel="next" href="courses?offset=10&amp;limit=10"/>
      <osearch:startIndex>0</osearch:startIndex>
    </feed>
  XML

  # A collision case: the same local name carries two different namespaces
  # on the same parent. In :strip mode both become "id" and MUST fold into
  # an array (in document order). :preserve keeps them distinct by prefix.
  COLLISION_XML = <<~XML.freeze
    <root xmlns:a="urn:a" xmlns:b="urn:b">
      <a:id>111</a:id>
      <b:id>222</b:id>
    </root>
  XML

  ATTR_COLLISION_XML = <<~XML.freeze
    <root xmlns:a="urn:a" xmlns:b="urn:b" a:id="111" b:id="222"/>
  XML

  STRIP_FEED = {
    "feed" => {
      "base" => "https://kosapi.fit.cvut.cz/api/3",
      "lang" => "cs",
      "link" => {"rel" => "next", "href" => "courses?offset=10&limit=10"},
      "startIndex" => "0"
    }
  }.freeze

  PRESERVE_FEED = {
    "feed" => {
      "xmlns" => FEED_NS,
      "xmlns:atom" => ATOM_NS,
      "xmlns:osearch" => OSEARCH_NS,
      "xml:base" => "https://kosapi.fit.cvut.cz/api/3",
      "xml:lang" => "cs",
      "link" => {"atom:rel" => "next", "href" => "courses?offset=10&limit=10"},
      "osearch:startIndex" => "0"
    }
  }.freeze

  # ------------------------------------------------------------------
  # :strip mode (default)
  # ------------------------------------------------------------------

  def test_strip_is_default
    assert_equal strip_feed, MultiXML.parse(FEED_XML)
  end

  def test_strip_feed
    assert_equal strip_feed, MultiXML.parse(FEED_XML, namespaces: :strip)
  end

  def test_strip_collision_folds_into_array
    result = MultiXML.parse(COLLISION_XML, namespaces: :strip)

    assert_equal({"root" => {"id" => %w[111 222]}}, result)
  end

  def test_strip_attribute_collision_folds_into_array
    result = MultiXML.parse(ATTR_COLLISION_XML, namespaces: :strip)

    assert_equal({"root" => {"id" => %w[111 222]}}, result)
  end

  # ------------------------------------------------------------------
  # :preserve mode
  # ------------------------------------------------------------------

  def test_preserve_feed
    result = MultiXML.parse(FEED_XML, namespaces: :preserve)

    assert_equal preserve_feed, result
  end

  def test_preserve_collision_keeps_prefixes_distinct
    result = MultiXML.parse(COLLISION_XML, namespaces: :preserve)

    assert_equal({
      "root" => {
        "xmlns:a" => "urn:a",
        "xmlns:b" => "urn:b",
        "a:id" => "111",
        "b:id" => "222"
      }
    }, result)
  end

  def test_preserve_attribute_collision_keeps_prefixes_distinct
    result = MultiXML.parse(ATTR_COLLISION_XML, namespaces: :preserve)

    assert_equal({
      "root" => {
        "xmlns:a" => "urn:a",
        "xmlns:b" => "urn:b",
        "a:id" => "111",
        "b:id" => "222"
      }
    }, result)
  end

  # ------------------------------------------------------------------
  # Validation
  # ------------------------------------------------------------------

  def test_unknown_namespaces_mode_raises
    assert_raises(ArgumentError) do
      MultiXML.parse("<r/>", namespaces: :bogus)
    end
  end

  private

  # Expected shape under :strip. Unprefixed attrs on <link> win (attributes
  # merged into one element's hash). The `xml:` reserved-prefix attrs are
  # also stripped to match the behavior libxml/nokogiri exhibit today.
  def strip_feed
    STRIP_FEED
  end

  def preserve_feed
    PRESERVE_FEED
  end
end

# Parsers under test. Keep this list in sync with test/parser_integration_test.rb.
NAMESPACE_PARSERS = {
  "LibXML" => "libxml-ruby",
  "REXML" => "rexml/document",
  "Nokogiri" => "nokogiri",
  "Ox" => "ox",
  "Oga" => "oga",
  "libxml_sax" => "libxml-ruby",
  "nokogiri_sax" => "nokogiri"
}.freeze

require_parser = lambda do |name|
  next require(name) unless name == "oga"

  original_verbose = $VERBOSE
  $VERBOSE = nil
  begin
    require name
  ensure
    $VERBOSE = original_verbose
  end
end

NAMESPACE_PARSERS.each do |parser_name, require_name|
  require_parser.call(require_name)

  klass = Class.new(Minitest::Test) do
    include NamespaceHandlingMatrix

    const_set(:PARSER, parser_name)

    def setup
      @original_parser = MultiXML.instance_variable_get(:@parser)
      MultiXML.parser = self.class::PARSER
    rescue LoadError
      skip "Parser #{self.class::PARSER} couldn't be loaded"
    end

    def teardown
      return unless @original_parser

      MultiXML.instance_variable_set(:@parser, @original_parser)
    end
  end

  test_class_name = parser_name.split("_").map(&:capitalize).join
  Object.const_set("#{test_class_name}NamespaceTest", klass)
rescue LoadError
  next
end
