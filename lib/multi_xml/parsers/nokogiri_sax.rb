require "cgi"
require "nokogiri" unless defined?(::Nokogiri)
require "stringio"

module MultiXml
  # Namespace for XML parser implementations
  #
  # @api private
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

        handler = SaxHandler.new
        ::Nokogiri::XML::SAX::Parser.new(handler).parse(io)
        handler.result
      end

      # Nokogiri SAX handler that builds a hash tree while parsing
      #
      # @api private
      class SaxHandler < ::Nokogiri::XML::SAX::Document
        # Create a new SAX handler
        #
        # @api private
        # @return [SaxHandler] new handler instance
        def initialize
          super
          @result = {}
          @stack = [@result]
          @pending_attrs = []
        end

        # Get the parsed result
        #
        # @api private
        # @return [Hash] the parsed hash
        attr_reader :result

        # Handle start of document
        #
        # @api private
        # @return [void]
        def start_document
        end

        # Handle end of document
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
          push_element(name)
          @pending_attrs << attrs.to_h
        end

        # Handle end of an element
        #
        # @api private
        # @param _name [String] Element name (unused)
        # @return [void]
        def end_element(_name)
          apply_attributes(@pending_attrs.pop)
          strip_whitespace_content
          @stack.pop
        end

        # Handle character data
        #
        # @api private
        # @param text [String] Text content
        # @return [void]
        def characters(text) = append_text(text)
        alias_method :cdata_block, :characters

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
