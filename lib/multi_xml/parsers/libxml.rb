require "libxml"
require_relative "dom_parser"

module MultiXml
  module Parsers
    # XML parser using the LibXML library
    #
    # @api private
    module Libxml
      include DomParser
      extend self

      # Get the parse error class for this parser
      #
      # @api private
      # @return [Class] LibXML::XML::Error
      def parse_error = ::LibXML::XML::Error

      # Parse XML from an IO object
      #
      # @api private
      # @param io [IO] IO-like object containing XML
      # @return [Hash] Parsed XML as a hash
      # @raise [LibXML::XML::Error] if XML is malformed
      def parse(io)
        node_to_hash(LibXML::XML::Parser.io(io).parse.root)
      end

      private

      # Iterate over child nodes
      #
      # @param node [LibXML::XML::Node] Parent node
      # @return [void]
      def each_child(node, &) = node.each_child(&)

      # Iterate over attribute nodes
      #
      # @param node [LibXML::XML::Node] Element node
      # @return [void]
      def each_attr(node, &) = node.each_attr(&)

      # Get the name of a node or attribute
      #
      # @param node [LibXML::XML::Node] Node to get name from
      # @return [String] Node name
      def node_name(node) = node.name
    end
  end
end
