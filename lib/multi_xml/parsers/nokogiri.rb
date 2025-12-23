require "nokogiri"
require_relative "dom_parser"

module MultiXml
  module Parsers
    # XML parser using the Nokogiri library
    #
    # @api private
    module Nokogiri
      include DomParser
      extend self

      # Get the parse error class for this parser
      #
      # @api private
      # @return [Class] Nokogiri::XML::SyntaxError
      def parse_error = ::Nokogiri::XML::SyntaxError

      # Parse XML from an IO object
      #
      # @api private
      # @param io [IO] IO-like object containing XML
      # @return [Hash] Parsed XML as a hash
      # @raise [Nokogiri::XML::SyntaxError] if XML is malformed
      def parse(io)
        doc = ::Nokogiri::XML(io)
        raise doc.errors.first unless doc.errors.empty?

        node_to_hash(doc.root)
      end

      private

      # Iterate over child nodes
      #
      # @param node [Nokogiri::XML::Node] Parent node
      # @return [void]
      def each_child(node, &) = node.children.each(&)

      # Iterate over attribute nodes
      #
      # @param node [Nokogiri::XML::Node] Element node
      # @return [void]
      def each_attr(node, &) = node.attribute_nodes.each(&)

      # Get the name of a node or attribute
      #
      # @param node [Nokogiri::XML::Node] Node to get name from
      # @return [String] Node name
      def node_name(node) = node.node_name
    end
  end
end
