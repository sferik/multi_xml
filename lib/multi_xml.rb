require "bigdecimal"
require "date"
require "stringio"
require "time"
require "yaml"
require "multi_xml/constants"
require "multi_xml/errors"
require "multi_xml/file_like"
require "multi_xml/helpers"
require "multi_xml/parsing"

module MultiXml
  class << self
    include Helpers

    # Get the current parser class.
    def parser
      return @parser if defined?(@parser)

      self.parser = default_parser
      @parser
    end

    # The default parser based on what you currently have loaded and installed.
    # First checks to see if any parsers are already loaded, then checks to see which are installed.
    def default_parser
      detect_loaded_parser || detect_installable_parser || raise_no_parser_error
    end

    # Set the XML parser utilizing a symbol, string, or class.
    # Supported by default are:
    #
    # * <tt>:libxml</tt>
    # * <tt>:nokogiri</tt>
    # * <tt>:ox</tt>
    # * <tt>:rexml</tt>
    # * <tt>:oga</tt>
    def parser=(new_parser)
      @parser = resolve_parser(new_parser)
    end

    # Resolve a parser from a symbol, string, or class/module.
    # Returns the parser module/class.
    def resolve_parser(parser_spec)
      case parser_spec
      when String, Symbol
        require "multi_xml/parsers/#{parser_spec.to_s.downcase}"
        MultiXml::Parsers.const_get(parser_spec.to_s.split("_").collect(&:capitalize).join.to_s)
      when Class, Module
        parser_spec
      else
        raise("Did not recognize your parser specification. Please specify either a symbol or a class.")
      end
    end

    # Parse an XML string or IO into Ruby.
    #
    # <b>Options</b>
    #
    # <tt>:parser</tt> :: The parser to use for this parse operation. Can be a symbol
    #                     (e.g. +:nokogiri+), string, or class/module. Defaults to the class-level parser.
    #
    # <tt>:symbolize_keys</tt> :: If true, will use symbols instead of strings for the keys.
    #
    # <tt>:disallowed_types</tt> :: Types to disallow from being typecasted. Defaults to `['yaml', 'symbol']`. Use `[]` to allow all types.
    #
    # <tt>:typecast_xml_value</tt> :: If true, won't typecast values for parsed document
    def parse(xml, options = {})
      options = DEFAULT_OPTIONS.merge(options)
      current_parser = options[:parser] ? resolve_parser(options[:parser]) : parser
      xml, original_xml = prepare_xml(xml)

      return {} if xml_empty?(xml)

      hash = parse_with_error_handling(xml, original_xml, current_parser)
      hash = typecast_xml_value(hash, options[:disallowed_types]) if options[:typecast_xml_value]
      hash = symbolize_keys(hash) if options[:symbolize_keys]
      hash
    end

    private

    def prepare_xml(xml)
      xml = (xml || "").strip if xml.nil? || xml.respond_to?(:strip)
      original_xml = xml
      xml = StringIO.new(xml) unless xml.respond_to?(:read)
      [xml, original_xml]
    end

    def xml_empty?(xml)
      char = xml.getc
      return true if char.nil?

      xml.ungetc(char)
      false
    end

    def parse_with_error_handling(xml, original_xml, current_parser)
      undasherize_keys(current_parser.parse(xml) || {})
    rescue DisallowedTypeError
      raise
    rescue current_parser.parse_error => e
      xml_string = original_xml.respond_to?(:read) ? original_xml.tap(&:rewind).read : original_xml
      raise ParseError.new(e.message, xml: xml_string)
    end

    def detect_loaded_parser
      return :ox if defined?(::Ox)
      return :libxml if defined?(::LibXML)
      return :nokogiri if defined?(::Nokogiri)

      :oga if defined?(::Oga)
    end

    def detect_installable_parser
      REQUIREMENT_MAP.each do |library, parser|
        require library
        return parser
      rescue LoadError
        next
      end
      nil
    end

    def raise_no_parser_error
      raise(NoParserError,
        "No XML parser detected. If you're using Rubinius and Bundler, try adding an XML parser to your " \
        "Gemfile (e.g. libxml-ruby, nokogiri, or rubysl-rexml). For more information, see " \
        "https://github.com/sferik/multi_xml/issues/42.")
    end
  end
end
