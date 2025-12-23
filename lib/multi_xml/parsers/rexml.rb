require "rexml/document"

module MultiXml
  module Parsers
    # XML parser using Ruby's built-in REXML library
    #
    # @api private
    module Rexml
      extend self

      # Get the parse error class for this parser
      #
      # @api private
      # @return [Class] REXML::ParseException
      def parse_error = ::REXML::ParseException

      # Parse XML from an IO object
      #
      # @api private
      # @param io [IO] IO-like object containing XML
      # @return [Hash] Parsed XML as a hash
      # @raise [REXML::ParseException] if XML is malformed
      def parse(io)
        doc = REXML::Document.new(io)
        element_to_hash({}, doc.root)
      end

      private

      # Convert an element to hash format
      #
      # @param hash [Hash] Accumulator hash
      # @param element [REXML::Element] Element to convert
      # @return [Hash] Updated hash
      def element_to_hash(hash, element)
        add_to_hash(hash, element.name, collapse_element(element))
      end

      # Collapse an element into a hash with attributes and content
      #
      # @param element [REXML::Element] Element to collapse
      # @return [Hash] Hash representation
      def collapse_element(element)
        node_hash = element.attributes.each_with_object({}) { |(k, v), h| h[k] = v }

        if element.has_elements?
          element.each_element { |child| element_to_hash(node_hash, child) }
          add_text_content(node_hash, element) unless whitespace_only?(element)
        elsif node_hash.empty? || !whitespace_only?(element)
          add_text_content(node_hash, element)
        end

        node_hash
      end

      # Add text content from an element to a hash
      #
      # @param hash [Hash] Target hash
      # @param element [REXML::Element] Element with text
      # @return [Hash] Updated hash
      def add_text_content(hash, element)
        return hash unless element.has_text?

        text = element.texts.map(&:value).join
        add_to_hash(hash, TEXT_CONTENT_KEY, text)
      end

      # Add a value to a hash, handling duplicates as arrays
      #
      # @param hash [Hash] Target hash
      # @param key [String] Key to add
      # @param value [Object] Value to add
      # @return [Hash] Updated hash
      def add_to_hash(hash, key, value)
        existing = hash[key]
        hash[key] = if existing
          existing.is_a?(Array) ? existing << value : [existing, value]
        elsif value.is_a?(Array)
          [value]
        else
          value
        end
        hash
      end

      # Check if element contains only whitespace text
      #
      # @param element [REXML::Element] Element to check
      # @return [Boolean] true if whitespace only
      def whitespace_only?(element)
        element.texts.join.strip.empty?
      end
    end
  end
end
