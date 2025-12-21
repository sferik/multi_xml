module MultiXml
  class ParseError < StandardError
    attr_reader :xml

    def initialize(message = nil, xml: nil)
      @xml = xml
      super(message)
    end
  end

  class NoParserError < StandardError; end

  class DisallowedTypeError < StandardError
    def initialize(type)
      super("Disallowed type attribute: #{type.inspect}")
    end
  end
end
