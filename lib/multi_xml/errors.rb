module MultiXml
  # Raised when XML parsing fails. Preserves the original XML and underlying cause.
  class ParseError < StandardError
    attr_reader :xml, :cause

    def initialize(message = nil, xml: nil, cause: nil)
      @xml = xml
      @cause = cause
      super(message)
    end
  end

  # Raised when no XML parser library is available
  class NoParserError < StandardError; end

  # Raised when an XML type attribute is in the disallowed list
  class DisallowedTypeError < StandardError
    attr_reader :type

    def initialize(type)
      @type = type
      super("Disallowed type attribute: #{type.inspect}")
    end
  end
end
