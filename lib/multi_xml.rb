require "bigdecimal"
require "date"
require "stringio"
require "time"
require "yaml"
require_relative "multi_xml/constants"
require_relative "multi_xml/errors"
require_relative "multi_xml/file_like"
require_relative "multi_xml/helpers"

module MultiXml
  class << self
    include Helpers

    # Returns the current parser module
    def parser
      @parser ||= resolve_parser(detect_parser)
    end

    # Sets the XML parser
    #
    # @param new_parser [Symbol, String, Module] Parser specification
    #   - Symbol/String: :libxml, :nokogiri, :ox, :rexml, :oga
    #   - Module: Custom parser implementing parse(io) and parse_error
    def parser=(new_parser)
      @parser = resolve_parser(new_parser)
    end

    # Parse XML into a Ruby Hash
    #
    # @param xml [String, IO] XML content
    # @param options [Hash] Parsing options
    # @option options [Symbol, String, Module] :parser Parser to use
    # @option options [Boolean] :symbolize_keys Convert keys to symbols (default: false)
    # @option options [Array<String>] :disallowed_types Types to reject (default: ['yaml', 'symbol'])
    # @option options [Boolean] :typecast_xml_value Apply type conversions (default: true)
    # @return [Hash] Parsed XML as nested hash
    def parse(xml, options = {})
      options = DEFAULT_OPTIONS.merge(options)
      xml_parser = options[:parser] ? resolve_parser(options[:parser]) : parser

      io = normalize_input(xml)
      return {} if io.eof?

      result = parse_with_error_handling(io, xml, xml_parser)
      result = typecast_xml_value(result, options[:disallowed_types]) if options[:typecast_xml_value]
      result = symbolize_keys(result) if options[:symbolize_keys]
      result
    end

    private

    def resolve_parser(spec)
      case spec
      when String, Symbol then load_parser(spec)
      when Class, Module then spec
      else raise "Invalid parser specification: expected Symbol, String, or Module"
      end
    end

    def load_parser(name)
      require "multi_xml/parsers/#{name.to_s.downcase}"
      Parsers.const_get(camelize(name.to_s))
    end

    def camelize(name)
      name.split("_").map(&:capitalize).join
    end

    def detect_parser
      find_loaded_parser || find_available_parser || raise_no_parser_error
    end

    def find_loaded_parser
      return :ox if defined?(::Ox)
      return :libxml if defined?(::LibXML)
      return :nokogiri if defined?(::Nokogiri)
      return :oga if defined?(::Oga)

      nil
    end

    def find_available_parser
      PARSER_PREFERENCE.each do |library, parser_name|
        require library
        return parser_name
      rescue LoadError
        next
      end
      nil
    end

    def raise_no_parser_error
      raise NoParserError, <<~MSG.chomp
        No XML parser detected. Install one of: ox, nokogiri, libxml-ruby, or oga.
        See https://github.com/sferik/multi_xml for more information.
      MSG
    end

    def normalize_input(xml)
      return xml if xml.respond_to?(:read)

      StringIO.new(xml.to_s.strip)
    end

    def parse_with_error_handling(io, original_input, xml_parser)
      undasherize_keys(xml_parser.parse(io) || {})
    rescue DisallowedTypeError
      raise
    rescue xml_parser.parse_error => e
      xml_string = original_input.respond_to?(:read) ? original_input.tap(&:rewind).read : original_input.to_s
      raise ParseError.new(e.message, xml: xml_string, cause: e)
    end
  end
end
