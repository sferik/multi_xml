require "nokogiri" unless defined?(::Nokogiri)
require_relative "dom_parser"

module MultiXml
  module Parsers
    # XML parser using the Nokogiri library
    module Nokogiri
      include DomParser
      extend self

      def parse_error = ::Nokogiri::XML::SyntaxError

      def parse(io)
        doc = ::Nokogiri::XML(io)
        raise doc.errors.first unless doc.errors.empty?

        node_to_hash(doc.root)
      end

      private

      def each_child(node, &) = node.children.each(&)
      def each_attr(node, &) = node.attribute_nodes.each(&)
      def node_name(node) = node.node_name
    end
  end
end
