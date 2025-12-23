require "nokogiri"
require "stringio"
require_relative "sax_handler"

module MultiXml
  module Parsers
    # SAX-based parser using Nokogiri (faster for large documents)
    #
    # @api private
    module NokogiriSax
      module_function

      # Get the parse error class for this parser
      #
      # @api private
      # @return [Class] Nokogiri::XML::SyntaxError
      def parse_error = ::Nokogiri::XML::SyntaxError

      # Parse XML from a string or IO object
      #
      # @api private
      # @param xml [String, IO] XML content
      # @return [Hash] Parsed XML as a hash
      # @raise [Nokogiri::XML::SyntaxError] if XML is malformed
      def parse(xml)
        io = xml.respond_to?(:read) ? xml : StringIO.new(xml)
        return {} if io.eof?

        handler = Handler.new
        ::Nokogiri::XML::SAX::Parser.new(handler).parse(io)
        handler.result
      end

      # Nokogiri SAX handler that builds a hash tree while parsing
      #
      # @api private
      class Handler < ::Nokogiri::XML::SAX::Document
        include SaxHandler

        # Create a new SAX handler
        #
        # @api private
        # @return [Handler] new handler instance
        def initialize
          super
          initialize_handler
        end

        # Handle start of document (no-op)
        #
        # @api private
        # @return [void]
        def start_document
        end

        # Handle end of document (no-op)
        #
        # @api private
        # @return [void]
        def end_document
        end

        # Handle parse errors
        #
        # @api private
        # @param message [String] Error message
        # @return [void]
        # @raise [Nokogiri::XML::SyntaxError] always
        def error(message)
          raise ::Nokogiri::XML::SyntaxError, message
        end

        # Handle start of an element
        #
        # @api private
        # @param name [String] Element name
        # @param attrs [Array] Element attributes as pairs
        # @return [void]
        def start_element(name, attrs = [])
          handle_start_element(name, attrs)
        end

        # Handle end of an element
        #
        # @api private
        # @param _name [String] Element name (unused)
        # @return [void]
        def end_element(_name)
          handle_end_element
        end

        # Handle character data
        #
        # @api private
        # @param text [String] Text content
        # @return [void]
        def characters(text) = append_text(text)
        alias_method :cdata_block, :characters
      end
    end
  end
end
