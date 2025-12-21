require "oga" unless defined?(::Oga)
require "multi_xml/parsers/libxml2_parser"

module MultiXml
  module Parsers
    module Oga # :nodoc:
      include Libxml2Parser
      extend self

      def parse_error
        LL::ParserError
      end

      def parse(io)
        document = ::Oga.parse_xml(io)
        node_to_hash(document.children[0])
      end

      def node_to_hash(node, hash = {}) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
        node_hash = {MultiXml::CONTENT_ROOT => ""}

        name = node_name(node)

        # Insert node hash into parent hash correctly.
        case hash[name]
        when Array
          hash[name] << node_hash
        when Hash
          hash[name] = [hash[name], node_hash]
        when NilClass
          hash[name] = node_hash
        end

        # Handle child elements
        each_child(node) do |c|
          if c.is_a?(::Oga::XML::Element)
            node_to_hash(c, node_hash)
          elsif c.is_a?(::Oga::XML::Text) || c.is_a?(::Oga::XML::Cdata)
            node_hash[MultiXml::CONTENT_ROOT] += c.text
          end
        end

        # Handle attributes
        each_attr(node) do |a|
          key = node_name(a)
          v = node_hash[key]
          node_hash[key] = (v ? [a.value, v] : a.value)
        end

        # Remove content node if:
        # 1. It is completely empty (no text at all), OR
        # 2. It is whitespace-only AND there are child elements/attributes
        # (consistent with ActiveSupport::XmlMini behavior)
        content = node_hash[MultiXml::CONTENT_ROOT]
        node_hash.delete(MultiXml::CONTENT_ROOT) if content.empty? || (node_hash.length > 1 && content.strip.empty?)

        hash
      end

      private

      def each_child(node, &)
        node.children.each(&)
      end

      def each_attr(node, &)
        node.attributes.each(&)
      end

      def node_name(node)
        node.name
      end
    end
  end
end
