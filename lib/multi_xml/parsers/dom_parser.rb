module MultiXml
  module Parsers
    # Shared DOM traversal logic for converting XML nodes to hashes
    #
    # Used by Nokogiri, LibXML, and Oga parsers.
    # Including modules must implement:
    # - each_child(node) { |child| ... }
    # - each_attr(node) { |attr| ... }
    # - node_name(node) -> String
    #
    # @api private
    module DomParser
      # Convert an XML node to a hash representation
      #
      # @api private
      # @param node [Object] XML node to convert
      # @param hash [Hash] Accumulator hash for results
      # @return [Hash] Hash representation of the node
      def node_to_hash(node, hash = {})
        node_hash = {TEXT_CONTENT_KEY => +""}
        add_value(hash, node_name(node), node_hash)
        collect_children(node, node_hash)
        collect_attributes(node, node_hash)
        strip_whitespace_content(node_hash)
        hash
      end

      private

      # Add a value to a hash, converting to array on duplicates
      #
      # @api private
      # @param hash [Hash] Target hash
      # @param key [String] Key to add
      # @param value [Object] Value to add
      # @return [void]
      def add_value(hash, key, value)
        existing = hash[key]
        hash[key] = case existing
        when Array then existing << value
        when Hash then [existing, value]
        else value
        end
      end

      # Collect all child nodes into a hash
      #
      # @api private
      # @param node [Object] Parent node
      # @param node_hash [Hash] Hash to populate
      # @return [void]
      def collect_children(node, node_hash)
        each_child(node) do |child|
          if child.element?
            node_to_hash(child, node_hash)
          elsif text_or_cdata?(child)
            node_hash[TEXT_CONTENT_KEY] << child.content
          end
        end
      end

      # Check if a node is text or CDATA
      #
      # @api private
      # @param node [Object] Node to check
      # @return [Boolean] true if text or CDATA
      def text_or_cdata?(node)
        node.text? || node.cdata?
      end

      # Collect all attributes from a node
      #
      # @api private
      # @param node [Object] Node with attributes
      # @param node_hash [Hash] Hash to populate
      # @return [void]
      def collect_attributes(node, node_hash)
        each_attr(node) do |attr|
          name = node_name(attr)
          existing = node_hash[name]
          node_hash[name] = existing ? [attr.value, existing] : attr.value
        end
      end

      # Remove empty or whitespace-only text content
      #
      # @api private
      # @param node_hash [Hash] Hash to clean up
      # @return [void]
      def strip_whitespace_content(node_hash)
        content = node_hash[TEXT_CONTENT_KEY]
        should_remove = content.empty? || (node_hash.size > 1 && content.strip.empty?)
        node_hash.delete(TEXT_CONTENT_KEY) if should_remove
      end
    end
  end
end
