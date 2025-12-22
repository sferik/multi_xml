require "cgi/escape"
require "libxml" unless defined?(::LibXML)
require "stringio"

module MultiXml
  # Namespace for XML parser implementations
  #
  # @api private
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
        handler = SaxHandler.new
        parser = ::LibXML::XML::SaxParser.io(io)
        parser.callbacks = handler
        parser.parse
        handler.result
      end

      # LibXML SAX handler that builds a hash tree while parsing
      #
      # @api private
      class SaxHandler
        include ::LibXML::XML::SaxParser::Callbacks

        # Create a new SAX handler
        #
        # @api private
        # @return [SaxHandler] new handler instance
        def initialize
          @result = {}
          @stack = [@result]
          @pending_attrs = []
          @error = nil
        end

        # Get the parsed result
        #
        # @api private
        # @return [Hash] the parsed hash
        # @raise [LibXML::XML::Error] if parsing failed
        def result
          raise @error if @error

          @result
        end

        # Handle start of document
        #
        # @api private
        # @return [void]
        def on_start_document
        end

        # Handle end of document
        #
        # @api private
        # @return [void]
        def on_end_document
        end

        # Handle parse errors
        #
        # @api private
        # @param error [String] Error message
        # @return [void]
        def on_error(error)
          @error = ::LibXML::XML::Error.new(error)
        end

        # Handle start of an element
        #
        # @api private
        # @param name [String] Element name
        # @param attrs [Hash] Element attributes
        # @return [void]
        def on_start_element(name, attrs = {})
          push_element(name)
          @pending_attrs << attrs
        end

        # Handle end of an element
        #
        # @api private
        # @param _name [String] Element name (unused)
        # @return [void]
        def on_end_element(_name)
          apply_attributes(@pending_attrs.pop)
          strip_whitespace_content
          @stack.pop
        end

        # Handle character data
        #
        # @api private
        # @param text [String] Text content
        # @return [void]
        def on_characters(text) = append_text(text)
        alias_method :on_cdata_block, :on_characters

        private

        # Get the current element hash
        #
        # @api private
        # @return [Hash] current hash being built
        def current = @stack.last

        # Push a new element onto the stack
        #
        # @api private
        # @param name [String] Element name
        # @return [void]
        def push_element(name)
          child = {TEXT_CONTENT_KEY => +""}
          add_value(name, child)
          @stack << child
        end

        # Append text to the current element
        #
        # @api private
        # @param text [String] Text to append
        # @return [void]
        def append_text(text)
          current[TEXT_CONTENT_KEY] << text
        end

        # Add a value to the current hash
        #
        # @api private
        # @param name [String] Key name
        # @param value [Object] Value to add
        # @return [void]
        def add_value(name, value)
          existing = current[name]
          current[name] = case existing
          when Array then existing << value
          when Hash then [existing, value]
          else value
          end
        end

        # Apply pending attributes to the current element
        #
        # @api private
        # @param attrs [Hash] Attributes to apply
        # @return [void]
        def apply_attributes(attrs)
          attrs.each do |name, value|
            value = CGI.unescapeHTML(value)
            existing = current[name]
            current[name] = existing ? [value, existing] : value
          end
        end

        # Remove empty or whitespace-only text content
        #
        # @api private
        # @return [void]
        def strip_whitespace_content
          content = current[TEXT_CONTENT_KEY]
          current.delete(TEXT_CONTENT_KEY) if content.empty? || (current.size > 1 && content.strip.empty?)
        end
      end
    end
  end
end
