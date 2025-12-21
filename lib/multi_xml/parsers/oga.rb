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

      def process_children(node, node_hash)
        each_child(node) do |c|
          if c.is_a?(::Oga::XML::Element)
            node_to_hash(c, node_hash)
          elsif c.is_a?(::Oga::XML::Text) || c.is_a?(::Oga::XML::Cdata)
            node_hash[MultiXml::CONTENT_ROOT] += c.text
          end
        end
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
