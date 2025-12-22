module MultiXml
  # Raised when XML parsing fails
  #
  # Preserves the original XML and underlying cause for debugging.
  #
  # @api public
  # @example Catching a parse error
  #   begin
  #     MultiXml.parse('<invalid>')
  #   rescue MultiXml::ParseError => e
  #     puts e.xml   # The malformed XML
  #     puts e.cause # The underlying parser exception
  #   end
  class ParseError < StandardError
    # The original XML that failed to parse
    #
    # @api public
    # @return [String, nil] the XML string that caused the error
    # @example Access the failing XML
    #   error.xml #=> "<invalid>"
    attr_reader :xml

    # The underlying parser exception
    #
    # @api public
    # @return [Exception, nil] the original exception from the parser
    # @example Access the cause
    #   error.cause #=> #<Nokogiri::XML::SyntaxError: ...>
    attr_reader :cause

    # Create a new ParseError
    #
    # @api public
    # @param message [String, nil] Error message
    # @param xml [String, nil] The original XML that failed to parse
    # @param cause [Exception, nil] The underlying parser exception
    # @return [ParseError] the new error instance
    # @example Create a parse error
    #   ParseError.new("Invalid XML", xml: "<bad>", cause: original_error)
    def initialize(message = nil, xml: nil, cause: nil)
      @xml = xml
      @cause = cause
      super(message)
    end
  end

  # Raised when no XML parser library is available
  #
  # This error is raised when MultiXml cannot find any supported XML parser.
  # Install one of: ox, nokogiri, libxml-ruby, or oga.
  #
  # @api public
  # @example Catching the error
  #   begin
  #     MultiXml.parse('<root/>')
  #   rescue MultiXml::NoParserError => e
  #     puts "Please install an XML parser gem"
  #   end
  class NoParserError < StandardError; end

  # Raised when an XML type attribute is in the disallowed list
  #
  # By default, 'yaml' and 'symbol' types are disallowed for security reasons.
  #
  # @api public
  # @example Catching a disallowed type error
  #   begin
  #     MultiXml.parse('<data type="yaml">--- :key</data>')
  #   rescue MultiXml::DisallowedTypeError => e
  #     puts e.type #=> "yaml"
  #   end
  class DisallowedTypeError < StandardError
    # The disallowed type that was encountered
    #
    # @api public
    # @return [String] the type attribute value that was disallowed
    # @example Access the disallowed type
    #   error.type #=> "yaml"
    attr_reader :type

    # Create a new DisallowedTypeError
    #
    # @api public
    # @param type [String] The disallowed type attribute value
    # @return [DisallowedTypeError] the new error instance
    # @example Create a disallowed type error
    #   DisallowedTypeError.new("yaml")
    def initialize(type)
      @type = type
      super("Disallowed type attribute: #{type.inspect}")
    end
  end
end
