module MultiXml
  module Parsers
    # Shared DOM traversal logic for converting XML nodes to hashes.
    # Used by Nokogiri, LibXML, and Oga parsers.
    #
    # Including modules must implement:
    #   - each_child(node) { |child| ... }
    #   - each_attr(node) { |attr| ... }
    #   - node_name(node) -> String
    module DomParser
      def node_to_hash(node, hash = {})
        node_hash = {TEXT_CONTENT_KEY => +""}
        add_value(hash, node_name(node), node_hash)
        collect_children(node, node_hash)
        collect_attributes(node, node_hash)
        strip_whitespace_content(node_hash)
        hash
      end

      private

      def add_value(hash, key, value)
        existing = hash[key]
        hash[key] = case existing
        when Array then existing << value
        when Hash then [existing, value]
        else value
        end
      end

      def collect_children(node, node_hash)
        each_child(node) do |child|
          if child.element?
            node_to_hash(child, node_hash)
          elsif child.text? || child.cdata?
            node_hash[TEXT_CONTENT_KEY] << child.content
          end
        end
      end

      def collect_attributes(node, node_hash)
        each_attr(node) do |attr|
          name = node_name(attr)
          existing = node_hash[name]
          node_hash[name] = existing ? [attr.value, existing] : attr.value
        end
      end

      def strip_whitespace_content(node_hash)
        content = node_hash[TEXT_CONTENT_KEY]
        removable = content.empty? || (node_hash.size > 1 && content.strip.empty?)
        node_hash.delete(TEXT_CONTENT_KEY) if removable
      end
    end
  end
end
