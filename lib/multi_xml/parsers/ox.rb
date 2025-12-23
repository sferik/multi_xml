require "ox"

module MultiXml
  module Parsers
    # XML parser using the Ox library (fastest pure-Ruby parser)
    #
    # @api private
    module Ox
      module_function

      # Get the parse error class for this parser
      #
      # @api private
      # @return [Class] Ox::ParseError
      def parse_error = ::Ox::ParseError

      # Parse XML from an IO object
      #
      # @api private
      # @param io [IO] IO-like object containing XML
      # @return [Hash] Parsed XML as a hash
      def parse(io)
        handler = Handler.new
        ::Ox.sax_parse(handler, io, convert_special: true, skip: :skip_return)
        handler.result
      end

      # SAX event handler that builds a hash tree while parsing
      #
      # @api private
      class Handler
        # Create a new SAX handler
        #
        # @return [Handler] new handler instance
        def initialize
          @stack = []
        end

        # Get the parsed result
        #
        # @return [Hash, nil] the root hash or nil if empty
        def result = @stack.first

        # Handle start of an element
        #
        # @param name [Symbol] Element name
        # @return [void]
        def start_element(name)
          @stack << {} if @stack.empty?
          child = {}
          add_value(name.to_s, child)
          @stack << child
        end

        # Handle end of an element
        #
        # @param _name [Symbol] Element name (unused)
        # @return [void]
        def end_element(_name)
          strip_whitespace_content if current.key?(TEXT_CONTENT_KEY)
          @stack.pop
        end

        # Handle an attribute
        #
        # @param name [Symbol] Attribute name
        # @param value [String] Attribute value
        # @return [void]
        def attr(name, value)
          add_value(name.to_s, value) unless @stack.empty?
        end

        # Handle text content
        #
        # @param value [String] Text content
        # @return [void]
        def text(value) = add_value(TEXT_CONTENT_KEY, value)

        # Handle CDATA content
        #
        # @param value [String] CDATA content
        # @return [void]
        def cdata(value) = add_value(TEXT_CONTENT_KEY, value)

        # Handle parse errors
        #
        # @param message [String] Error message
        # @param line [Integer] Line number
        # @param column [Integer] Column number
        # @return [void]
        # @raise [Ox::ParseError] always
        def error(message, line, column)
          raise ::Ox::ParseError, "#{message} at #{line}:#{column}"
        end

        private

        # Get the current element hash
        #
        # @return [Hash] current hash being built
        def current = @stack.last

        # Add a value to the current hash, merging with existing if needed
        #
        # @param key [String] Key to add
        # @param value [Object] Value to add
        # @return [void]
        def add_value(key, value)
          existing = current[key]
          current[key] = existing ? merge_values(existing, value) : value
        end

        # Merge a value with an existing value, creating array if needed
        #
        # @param existing [Object] Existing value
        # @param value [Object] Value to append
        # @return [Array] array with both values
        def merge_values(existing, value)
          existing.is_a?(Array) ? existing << value : [existing, value]
        end

        # Remove empty or whitespace-only text content
        #
        # @return [void]
        def strip_whitespace_content
          content = current[TEXT_CONTENT_KEY]
          should_remove = content.empty? || (current.size > 1 && content.strip.empty?)
          current.delete(TEXT_CONTENT_KEY) if should_remove
        end
      end
    end
  end
end
