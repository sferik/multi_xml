require "oga"
require_relative "dom_parser"

module MultiXml
  module Parsers
    # XML parser using the Oga library
    #
    # @api private
    module Oga
      include DomParser
      extend self

      # Get the parse error class for this parser
      #
      # @api private
      # @return [Class] LL::ParserError
      def parse_error = LL::ParserError

      # Parse XML from an IO object
      #
      # @api private
      # @param io [IO] IO-like object containing XML
      # @return [Hash] Parsed XML as a hash
      # @raise [LL::ParserError] if XML is malformed
      def parse(io)
        doc = ::Oga.parse_xml(io)
        node_to_hash(doc.children.first)
      end

      # Collect child nodes into a hash (Oga-specific implementation)
      #
      # Oga uses different node types than Nokogiri/LibXML.
      #
      # @api private
      # @param node [Oga::XML::Element] Parent node
      # @param node_hash [Hash] Hash to populate
      # @return [void]
      def collect_children(node, node_hash)
        each_child(node) do |child|
          case child
          when ::Oga::XML::Element then node_to_hash(child, node_hash)
          when ::Oga::XML::Text, ::Oga::XML::Cdata then node_hash[TEXT_CONTENT_KEY] << child.text
          end
        end
      end

      private

      # Iterate over child nodes
      #
      # @param node [Oga::XML::Element] Parent node
      # @return [void]
      def each_child(node, &) = node.children.each(&)

      # Iterate over attribute nodes
      #
      # @param node [Oga::XML::Element] Element node
      # @return [void]
      def each_attr(node, &) = node.attributes.each(&)

      # Get the name of a node or attribute
      #
      # @param node [Oga::XML::Node] Node to get name from
      # @return [String] Node name
      def node_name(node) = node.name
    end
  end
end
