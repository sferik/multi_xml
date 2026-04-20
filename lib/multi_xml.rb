require "bigdecimal"
require "date"
require "stringio"
require "time"
require "yaml"
require_relative "multi_xml/constants"
require_relative "multi_xml/errors"
require_relative "multi_xml/file_like"
require_relative "multi_xml/helpers"
require_relative "multi_xml/parser_resolution"
require_relative "multi_xml/parse_support"

# A generic swappable back-end for parsing XML
#
# MultiXml provides a unified interface for XML parsing across different
# parser libraries. It automatically selects the best available parser
# (Ox, LibXML, Nokogiri, Oga, or REXML) and converts XML to Ruby hashes.
#
# @api public
# @example Parse XML
#   MultiXml.parse('<root><name>John</name></root>')
#   #=> {"root"=>{"name"=>"John"}}
#
# @example Set the parser
#   MultiXml.parser = :nokogiri
module MultiXml
  class << self
    include Helpers
    include ParserResolution
    include ParseSupport

    # Get the current XML parser module
    #
    # Returns the currently configured parser, auto-detecting one if not set.
    # Parsers are checked in order of performance: Ox, LibXML, Nokogiri, Oga, REXML.
    #
    # @api public
    # @return [Module] the current parser module
    # @example Get current parser
    #   MultiXml.parser #=> MultiXml::Parsers::Ox
    def parser
      @parser ||= resolve_parser(detect_parser)
    end

    # Set the XML parser to use
    #
    # @api public
    # @param new_parser [Symbol, String, Module] Parser specification
    #   - Symbol/String: :libxml, :nokogiri, :ox, :rexml, :oga
    #   - Module: Custom parser implementing parse(io) or
    #             parse(io, namespaces: ...) and parse_error
    # @return [Module] the newly configured parser module
    # @example Set parser by symbol
    #   MultiXml.parser = :nokogiri
    # @example Set parser by module
    #   MultiXml.parser = MyCustomParser
    def parser=(new_parser)
      @parser = resolve_parser(new_parser)
    end

    # Parse XML into a Ruby Hash
    #
    # @api public
    # @param xml [String, IO] XML content as a string or IO-like object
    # @param options [Hash] Parsing options
    # @option options [Symbol, String, Module] :parser Parser to use for this call
    # @option options [Boolean] :symbolize_keys Convert keys to symbols (default: false)
    # @option options [Array<String>] :disallowed_types Types to reject (default: ['yaml', 'symbol'])
    # @option options [Boolean] :typecast_xml_value Apply type conversions (default: true)
    # @option options [Symbol] :namespaces Namespace handling mode (:strip or :preserve)
    # @return [Hash] Parsed XML as nested hash
    # @raise [ParseError] if XML is malformed
    # @raise [DisallowedTypeError] if XML contains a disallowed type attribute
    # @example Parse simple XML
    #   MultiXml.parse('<root><name>John</name></root>')
    #   #=> {"root"=>{"name"=>"John"}}
    # @example Parse with symbolized keys
    #   MultiXml.parse('<root><name>John</name></root>', symbolize_keys: true)
    #   #=> {root: {name: "John"}}
    def parse(xml, options = {})
      options = DEFAULT_OPTIONS.merge(options)
      namespaces = validate_namespaces_mode(options.fetch(:namespaces))
      io = normalize_input(xml)
      return {} if io.eof?

      result = parse_with_error_handling(io, xml, resolve_parse_parser(options), namespaces)
      apply_postprocessing(result, options)
    end
  end
end
