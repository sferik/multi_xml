require "bigdecimal"
require "date"
require "stringio"
require "time"
require "yaml"
require_relative "multi_xml/constants"
require_relative "multi_xml/errors"
require_relative "multi_xml/file_like"
require_relative "multi_xml/helpers"

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
    #   - Module: Custom parser implementing parse(io) and parse_error
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
      xml_parser = options[:parser] ? resolve_parser(options.fetch(:parser)) : parser

      io = normalize_input(xml)
      return {} if io.eof?

      result = parse_with_error_handling(io, xml, xml_parser)
      result = typecast_xml_value(result, options.fetch(:disallowed_types)) if options.fetch(:typecast_xml_value)
      result = symbolize_keys(result) if options.fetch(:symbolize_keys)
      result
    end

    private

    # Resolve a parser specification to a module
    #
    # @api private
    # @param spec [Symbol, String, Class, Module] Parser specification
    # @return [Module] Resolved parser module
    # @raise [RuntimeError] if spec is invalid
    def resolve_parser(spec)
      case spec
      when String, Symbol then load_parser(spec)
      when Module then spec
      else raise "Invalid parser specification: expected Symbol, String, or Module"
      end
    end

    # Load a parser by name
    #
    # @api private
    # @param name [Symbol, String] Parser name
    # @return [Module] Loaded parser module
    def load_parser(name)
      name = name.to_s.downcase
      require "multi_xml/parsers/#{name}"
      Parsers.const_get(camelize(name))
    end

    # Convert underscored string to CamelCase
    #
    # @api private
    # @param name [String] Underscored string
    # @return [String] CamelCased string
    def camelize(name)
      name.split("_").map(&:capitalize).join
    end

    # Detect the best available parser
    #
    # @api private
    # @return [Symbol] Parser name
    # @raise [NoParserError] if no parser is available
    def detect_parser
      find_loaded_parser || find_available_parser || raise_no_parser_error
    end

    # Parser constant names mapped to their symbols, in preference order
    #
    # @api private
    LOADED_PARSER_CHECKS = {
      Ox: :ox,
      LibXML: :libxml,
      Nokogiri: :nokogiri,
      Oga: :oga
    }.freeze
    private_constant :LOADED_PARSER_CHECKS

    # Find an already-loaded parser library
    #
    # @api private
    # @return [Symbol, nil] Parser name or nil if none loaded
    def find_loaded_parser
      LOADED_PARSER_CHECKS.each do |const_name, parser_name|
        return parser_name if const_defined?(const_name)
      end
      nil
    end

    # Try to load and find an available parser
    #
    # @api private
    # @return [Symbol, nil] Parser name or nil if none available
    def find_available_parser
      PARSER_PREFERENCE.each do |library, parser_name|
        return parser_name if try_require(library)
      end
      nil
    end

    # Attempt to require a library
    #
    # @api private
    # @param library [String] Library to require
    # @return [Boolean] true if successful, false if LoadError
    def try_require(library)
      require library
      true
    rescue LoadError
      false
    end

    # Raise an error indicating no parser is available
    #
    # @api private
    # @return [void]
    # @raise [NoParserError] always
    def raise_no_parser_error
      raise NoParserError, <<~MSG.chomp
        No XML parser detected. Install one of: ox, nokogiri, libxml-ruby, or oga.
        See https://github.com/sferik/multi_xml for more information.
      MSG
    end

    # Normalize input to an IO-like object
    #
    # @api private
    # @param xml [String, IO] Input to normalize
    # @return [IO] IO-like object
    def normalize_input(xml)
      return xml if xml.respond_to?(:read)

      StringIO.new(xml.to_s.strip)
    end

    # Parse XML with error handling and key normalization
    #
    # @api private
    # @param io [IO] IO-like object containing XML
    # @param original_input [String, IO] Original input for error reporting
    # @param xml_parser [Module] Parser to use
    # @return [Hash] Parsed XML with undasherized keys
    # @raise [ParseError] if XML is malformed
    def parse_with_error_handling(io, original_input, xml_parser)
      undasherize_keys(xml_parser.parse(io) || {})
    rescue xml_parser.parse_error => e
      xml_string = original_input.respond_to?(:read) ? original_input.tap(&:rewind).read : original_input.to_s
      raise(ParseError.new(e, xml: xml_string, cause: e))
    end
  end
end
