require "oga" unless defined?(::Oga)
require_relative "dom_parser"

module MultiXml
  module Parsers
    # XML parser using the Oga library
    module Oga
      include DomParser
      extend self

      def parse_error = LL::ParserError

      def parse(io)
        doc = ::Oga.parse_xml(io)
        node_to_hash(doc.children.first)
      end

      # Oga uses different node types than Nokogiri/LibXML
      def collect_children(node, node_hash)
        each_child(node) do |child|
          case child
          when ::Oga::XML::Element
            node_to_hash(child, node_hash)
          when ::Oga::XML::Text, ::Oga::XML::Cdata
            node_hash[TEXT_CONTENT_KEY] << child.text
          end
        end
      end

      private

      def each_child(node, &) = node.children.each(&)
      def each_attr(node, &) = node.attributes.each(&)
      def node_name(node) = node.name
    end
  end
end
