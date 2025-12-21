module MultiXml
  module Parsers
    module Libxml2Parser # :nodoc:
      # Convert XML document to hash
      #
      # node::
      #   The XML node object to convert to a hash.
      #
      # hash::
      #   Hash to merge the converted element into.
      def node_to_hash(node, hash = {})
        node_hash = {MultiXml::CONTENT_ROOT => ""}
        insert_node_hash(hash, node_name(node), node_hash)
        process_children(node, node_hash)
        process_attributes(node, node_hash)
        remove_empty_content(node_hash)
        hash
      end

      def insert_node_hash(hash, name, node_hash)
        case hash[name]
        when Array then hash[name] << node_hash
        when Hash then hash[name] = [hash[name], node_hash]
        when NilClass then hash[name] = node_hash
        end
      end

      def process_children(node, node_hash)
        each_child(node) do |c|
          if c.element?
            node_to_hash(c, node_hash)
          elsif c.text? || c.cdata?
            node_hash[MultiXml::CONTENT_ROOT] += c.content
          end
        end
      end

      def process_attributes(node, node_hash)
        each_attr(node) do |a|
          key = node_name(a)
          v = node_hash[key]
          node_hash[key] = v ? [a.value, v] : a.value
        end
      end

      def remove_empty_content(node_hash)
        content = node_hash[MultiXml::CONTENT_ROOT]
        node_hash.delete(MultiXml::CONTENT_ROOT) if content.empty? || (node_hash.length > 1 && content.strip.empty?)
      end

      # Parse an XML Document IO into a simple hash.
      # xml::
      #   XML Document IO to parse
      def parse(_)
        raise(NotImplementedError, "inheritor should define #{__method__}")
      end

      private

      def each_child(*)
        raise(NotImplementedError, "inheritor should define #{__method__}")
      end

      def each_attr(*)
        raise(NotImplementedError, "inheritor should define #{__method__}")
      end

      def node_name(*)
        raise(NotImplementedError, "inheritor should define #{__method__}")
      end
    end
  end
end
