require "libxml-ruby"
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
      # @param namespaces [Symbol] Namespace handling mode
      # @return [Hash] Parsed XML as a hash
      # @raise [LibXML::XML::Error] if XML is malformed
      def parse(io, namespaces: :strip)
        node_to_hash(::LibXML::XML::Parser.io(io).parse.root, mode: namespaces)
      end

      private

      # Iterate over child nodes
      #
      # @api private
      # @param node [LibXML::XML::Node] Parent node
      # @return [void]
      def each_child(node, &) = node.each_child(&)

      # Iterate over attribute nodes
      #
      # @api private
      # @param node [LibXML::XML::Node] Element node
      # @return [void]
      def each_element_attr(node, &) = node.each_attr(&)

      # Yield each xmlns declaration on this element
      #
      # @api private
      # @param node [LibXML::XML::Node] Element node
      # @return [void]
      def each_namespace_decl(node)
        node.namespaces.definitions.each { |ns| yield ns.prefix, ns.href }
      end

      # Return [prefix, local] for an element
      #
      # @api private
      # @param node [LibXML::XML::Node] Element node
      # @return [Array<String, nil>] prefix and local name
      def element_parts(node)
        [node.namespaces.namespace&.prefix, node.name]
      end

      # Return [prefix, local] for an attribute
      #
      # @api private
      # @param attr [LibXML::XML::Attr] Attribute node
      # @return [Array<String, nil>] prefix and local name
      def attr_parts(attr)
        [attr.ns? ? attr.ns.prefix : nil, attr.name]
      end
    end
  end
end
