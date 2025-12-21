require "rexml/document" unless defined?(::REXML::Document)

module MultiXml
  module Parsers
    # XML parser using Ruby's built-in REXML library
    module Rexml
      extend self

      def parse_error = ::REXML::ParseException

      def parse(io)
        doc = REXML::Document.new(io)
        raise REXML::ParseException, "Document has no valid root element" unless doc.root

        element_to_hash({}, doc.root)
      end

      private

      def element_to_hash(hash, element)
        add_to_hash(hash, element.name, collapse_element(element))
      end

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

      def add_text_content(hash, element)
        return hash unless element.has_text?

        text = element.texts.map(&:value).join
        add_to_hash(hash, TEXT_CONTENT_KEY, text)
      end

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

      def whitespace_only?(element)
        element.texts.join.strip.empty?
      end
    end
  end
end
