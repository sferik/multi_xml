require "libxml"
require "stringio"
require_relative "sax_handler"

module MultiXml
  module Parsers
    # SAX-based parser using LibXML (faster for large documents)
    #
    # @api private
    module LibxmlSax
      module_function

      # Get the parse error class for this parser
      #
      # @api private
      # @return [Class] LibXML::XML::Error
      def parse_error = ::LibXML::XML::Error

      # Parse XML from a string or IO object
      #
      # @api private
      # @param xml [String, IO] XML content
      # @return [Hash] Parsed XML as a hash
      # @raise [LibXML::XML::Error] if XML is malformed
      def parse(xml)
        io = xml.respond_to?(:read) ? xml : StringIO.new(xml)
        return {} if io.eof?

        LibXML::XML::Error.set_handler(&LibXML::XML::Error::QUIET_HANDLER)
        handler = Handler.new
        parser = ::LibXML::XML::SaxParser.io(io)
        parser.callbacks = handler
        parser.parse
        handler.result
      end

      # LibXML SAX handler that builds a hash tree while parsing
      #
      # @api private
      class Handler
        include ::LibXML::XML::SaxParser::Callbacks
        include SaxHandler

        # Create a new SAX handler
        #
        # @api private
        # @return [Handler] new handler instance
        def initialize
          initialize_handler
        end

        # Handle start of document (no-op)
        #
        # @api private
        # @return [void]
        def on_start_document
        end

        # Handle end of document (no-op)
        #
        # @api private
        # @return [void]
        def on_end_document
        end

        # Handle parse errors (no-op, LibXML raises directly)
        #
        # @api private
        # @param _error [String] Error message (unused)
        # @return [void]
        def on_error(_error)
        end

        # Handle start of an element
        #
        # @api private
        # @param name [String] Element name
        # @param attrs [Hash] Element attributes
        # @return [void]
        def on_start_element(name, attrs = {})
          handle_start_element(name, attrs)
        end

        # Handle end of an element
        #
        # @api private
        # @param _name [String] Element name (unused)
        # @return [void]
        def on_end_element(_name)
          handle_end_element
        end

        # Handle character data
        #
        # @api private
        # @param text [String] Text content
        # @return [void]
        def on_characters(text) = append_text(text)
        alias_method :on_cdata_block, :on_characters
      end
    end
  end
end
