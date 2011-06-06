require 'nokogiri' unless defined?(Nokogiri)

module MultiXml
  module Parsers
    module Nokogiri #:nodoc:
      extend self
      def parse_error; ::Nokogiri::XML::SyntaxError; end

      # Parse an XML Document IO into a simple hash using Nokogiri.
      # xml::
      #   XML Document IO to parse
      def parse(xml)
        doc = ::Nokogiri::XML(xml)
        raise doc.errors.first if doc.errors.length > 0
        doc.to_hash
      end

      module Conversions #:nodoc:
        module Document #:nodoc:
          def to_hash
            root.to_hash
          end
        end

        module Node #:nodoc:
          # Convert XML document to hash
          #
          # hash::
          #   Hash to merge the converted element into.
          def to_hash(hash={})
            node_hash = {MultiXml::CONTENT_ROOT => ''}

            # Insert node hash into parent hash correctly.
            case hash[name]
              when Array then hash[name] << node_hash
              when Hash  then hash[name] = [hash[name], node_hash]
              when nil   then hash[name] = node_hash
            end

            # Handle child elements
            children.each do |c|
              if c.element?
                c.to_hash(node_hash)
              elsif c.text? || c.cdata?
                node_hash[MultiXml::CONTENT_ROOT] << c.content
              end
            end

            # Remove content node if it is empty
            if node_hash[MultiXml::CONTENT_ROOT].strip.empty?
              node_hash.delete(MultiXml::CONTENT_ROOT)
            end

            # Handle attributes
            attribute_nodes.each { |a| node_hash[a.node_name] = a.value }

            hash
          end
        end
      end

      ::Nokogiri::XML::Document.send(:include, Conversions::Document)
      ::Nokogiri::XML::Node.send(:include, Conversions::Node)
    end
  end
end
