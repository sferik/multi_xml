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
      # @api private
      # @param hash [Hash] Accumulator hash
      # @param element [REXML::Element] Element to convert
      # @return [Hash] Updated hash
      def element_to_hash(hash, element)
        add_to_hash(hash, element.name, collapse_element(element))
      end

      # Collapse an element into a hash with attributes and content
      #
      # @api private
      # @param element [REXML::Element] Element to collapse
      # @return [Hash] Hash representation
      def collapse_element(element)
        node_hash = collect_attributes(element)

        if element.has_elements?
          collect_child_elements(element, node_hash)
          add_text_content(node_hash, element) unless whitespace_only?(element)
        elsif node_hash.empty? || !whitespace_only?(element)
          add_text_content(node_hash, element)
        end

        node_hash
      end

      # Collect all attributes from an element into a hash
      #
      # @api private
      # @param element [REXML::Element] Element with attributes
      # @return [Hash] Hash of attribute name-value pairs
      def collect_attributes(element)
        element.attributes.each_with_object({}) { |(name, value), hash| hash[name] = value }
      end

      # Collect all child elements into a hash
      #
      # @api private
      # @param element [REXML::Element] Parent element
      # @param node_hash [Hash] Hash to populate
      # @return [void]
      def collect_child_elements(element, node_hash)
        element.each_element { |child| element_to_hash(node_hash, child) }
      end

      # Add text content from an element to a hash
      #
      # @api private
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
      # @api private
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
      # @api private
      # @param element [REXML::Element] Element to check
      # @return [Boolean] true if whitespace only
      def whitespace_only?(element)
        element.texts.join.strip.empty?
      end
    end
  end
end
