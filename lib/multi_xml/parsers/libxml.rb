require 'libxml' unless defined?(LibXML)

module MultiXml
  module Parsers
    module Libxml #:nodoc:
      extend self
      def parse_error; ::LibXML::XML::Error; end

      # Parse an XML Document string or IO into a simple hash using LibXML.
      # xml::
      #   XML Document string or IO to parse
      def parse(xml)
        if !xml.respond_to?(:read)
          xml = StringIO.new(xml || '')
        end

        char = xml.getc
        if char.nil?
          {}
        else
          xml.ungetc(char)
          LibXML::XML::Parser.io(xml).parse.to_hash
        end
      end
    end
  end
end

module LibXML #:nodoc:
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
        each_child do |c|
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
        each_attr { |a| node_hash[a.name] = a.value }

        hash
      end
    end
  end
end

LibXML::XML::Document.send(:include, LibXML::Conversions::Document)
LibXML::XML::Node.send(:include, LibXML::Conversions::Node)
