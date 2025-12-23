require "cgi/escape"

module MultiXml
  module Parsers
    # Shared SAX handler logic for building hash trees from XML events
    #
    # This module provides the core stack-based parsing logic used by both
    # NokogiriSax and LibxmlSax parsers. Including classes must implement
    # the callback methods that their respective SAX libraries expect.
    #
    # @api private
    module SaxHandler
      # Initialize the handler state
      #
      # @api private
      # @return [void]
      def initialize_handler
        @result = {}
        @stack = [@result]
        @pending_attrs = []
      end

      # Get the parsed result
      #
      # @api private
      # @return [Hash] the parsed hash
      attr_reader :result

      private

      # Get the current element hash
      #
      # @api private
      # @return [Hash] current hash being built
      def current = @stack.last

      # Handle start of an element by pushing onto the stack
      #
      # @api private
      # @param name [String] Element name
      # @param attrs [Hash, Array] Element attributes
      # @return [void]
      def handle_start_element(name, attrs)
        child = {TEXT_CONTENT_KEY => +""}
        add_child_to_current(name, child)
        @stack << child
        @pending_attrs << normalize_attrs(attrs)
      end

      # Handle end of an element by applying attributes and popping the stack
      #
      # @api private
      # @return [void]
      def handle_end_element
        apply_attributes(@pending_attrs.pop)
        strip_whitespace_content
        @stack.pop
      end

      # Append text to the current element's content
      #
      # @api private
      # @param text [String] Text to append
      # @return [void]
      def append_text(text)
        current[TEXT_CONTENT_KEY] << text
      end

      # Add a child hash to the current element
      #
      # @api private
      # @param name [String] Child element name
      # @param child [Hash] Child hash to add
      # @return [void]
      def add_child_to_current(name, child)
        existing = current[name]
        current[name] = case existing
        when Array then existing << child
        when Hash then [existing, child]
        else child
        end
      end

      # Normalize attributes to a hash
      #
      # @api private
      # @param attrs [Hash, Array] Attributes as hash or array of pairs
      # @return [Hash] Normalized attributes hash
      def normalize_attrs(attrs)
        attrs.is_a?(Hash) ? attrs : attrs.to_h
      end

      # Apply pending attributes to the current element
      #
      # @api private
      # @param attrs [Hash] Attributes to apply
      # @return [void]
      def apply_attributes(attrs)
        attrs.each do |name, value|
          unescaped = CGI.unescapeHTML(value)
          existing = current[name]
          current[name] = existing ? [unescaped, existing] : unescaped
        end
      end

      # Remove empty or whitespace-only text content
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
