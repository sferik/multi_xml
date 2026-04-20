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
      # @param namespaces [Symbol] Namespace handling mode
      # @return [Hash] Parsed XML as a hash
      def parse(io, namespaces: :strip)
        handler = Handler.new(namespaces)
        ::Ox.sax_parse(handler, io, convert_special: true, skip: :skip_return)
        handler.result
      end

      # SAX event handler that builds a hash tree while parsing.
      #
      # Ox's SAX callbacks expose element and attribute names in prefixed
      # form (e.g. "atom:feed"). Under :preserve we keep the source form
      # verbatim; under :strip we drop the prefix and filter xmlns
      # declarations out of the attribute stream.
      #
      # @api private
      class Handler
        # Create a new SAX handler
        #
        # @api private
        # @param mode [Symbol] Namespace handling mode
        # @return [Handler] new handler instance
        def initialize(mode)
          @mode = mode
          @stack = [{}]
        end

        # Get the parsed result
        #
        # @api private
        # @return [Hash] the parsed hash
        def result = @stack.first

        # Handle start of an element
        #
        # @api private
        # @param name [Symbol, String] Element name
        # @return [void]
        def start_element(name)
          child = {}
          add_value(current, format_name(name.to_s), child)
          @stack << child
        end

        # Handle an attribute
        #
        # Ignored outside an element (e.g. attributes on the XML declaration
        # such as `<?xml version="1.0"?>`, which fire before any `start_element`).
        #
        # @api private
        # @param name [Symbol, String] Attribute name
        # @param value [String] Attribute value
        # @return [void]
        def attr(name, value)
          return if @stack.size < 2

          name = name.to_s
          return if xmlns_decl?(name) && @mode != :preserve

          add_attribute_value(current, format_name(name), value)
        end

        # Handle text content (also aliased as `cdata`)
        #
        # @api private
        # @param value [String] Text content
        # @return [void]
        def text(value) = add_value(current, TEXT_CONTENT_KEY, value)
        alias_method :cdata, :text

        # Handle end of an element
        #
        # @api private
        # @param _name [Symbol, String] Element name (unused)
        # @return [void]
        def end_element(_name)
          strip_whitespace_content if current.key?(TEXT_CONTENT_KEY)
          @stack.pop
        end

        # Handle parse errors
        #
        # @api private
        # @param message [String] Error message
        # @param line [Integer] Line number
        # @param column [Integer] Column number
        # @return [void]
        # @raise [Ox::ParseError] always
        def error(message, line, column)
          raise ::Ox::ParseError, "#{message} at #{line}:#{column}"
        end

        private

        # Current element hash on top of the stack
        #
        # @api private
        # @return [Hash] current hash being built
        def current = @stack.last

        # Format a prefixed-or-local name according to the namespace mode
        #
        # @api private
        # @param name [String] Prefixed or local name
        # @return [String] formatted name
        def format_name(name)
          (@mode == :preserve) ? name : name.split(":", 2).last
        end

        # Check whether an attribute name is an xmlns declaration
        #
        # @api private
        # @param name [String] Attribute name
        # @return [Boolean] true if xmlns or xmlns:*
        def xmlns_decl?(name)
          name == "xmlns" || name.start_with?("xmlns:")
        end

        # Add a value to a hash, folding into an array on collision
        #
        # @api private
        # @param hash [Hash] Target hash
        # @param key [String] Key to add
        # @param value [Object] Value to add
        # @return [void]
        def add_value(hash, key, value)
          existing = hash[key]
          hash[key] = existing ? merge_values(existing, value) : value
        end

        # Merge a value with an existing value, creating an array if needed
        #
        # @api private
        # @param existing [Object] Existing value
        # @param value [Object] Value to append
        # @return [Array] array with both values
        def merge_values(existing, value)
          existing.is_a?(Array) ? existing << value : [existing, value]
        end

        # Add an attribute value while keeping document order on collisions
        #
        # @api private
        # @param hash [Hash] Target hash
        # @param key [String] Attribute key
        # @param value [String] Attribute value
        # @return [void]
        def add_attribute_value(hash, key, value)
          existing = hash[key]
          hash[key] = case existing
          when nil then value
          when Array then insert_attribute_before_children(existing, value)
          when Hash then [value, existing]
          else [existing, value]
          end
        end

        # Insert a later attribute before any child-element entries
        #
        # @api private
        # @param values [Array] Existing colliding values
        # @param value [String] Attribute value to insert
        # @return [Array] Updated value list
        def insert_attribute_before_children(values, value)
          child_index = values.index { |entry| entry.is_a?(Hash) } || values.length
          values.dup.insert(child_index, value)
        end

        # Remove empty or whitespace-only text content from the current hash
        #
        # @api private
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
