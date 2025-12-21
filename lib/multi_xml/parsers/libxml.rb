require "libxml" unless defined?(::LibXML)
require_relative "dom_parser"

module MultiXml
  module Parsers
    # XML parser using the LibXML library
    module Libxml
      include DomParser
      extend self

      def parse_error = ::LibXML::XML::Error

      def parse(io)
        node_to_hash(LibXML::XML::Parser.io(io).parse.root)
      end

      private

      def each_child(node, &) = node.each_child(&)
      def each_attr(node, &) = node.each_attr(&)
      def node_name(node) = node.name
    end
  end
end
