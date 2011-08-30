require 'ox' unless defined?(Ox)

module MultiXml
  module Parsers
    module Ox #:nodoc:

      extend self
      
      def parse_error
        Exception
      end

      def parse(xml)
        doc = ::Ox.parse(xml)
        h = { }
        element_to_hash(doc, h) unless doc.nil?
        h
      end

      def element_to_hash(e, h)
        content = { }
        e.attributes.each do |k,v|
          content[k.to_s] = v
        end
        e.nodes.each do |n|
          if n.is_a?(::Ox::Element)
            element_to_hash(n, content)
          elsif n.is_a?(String)
            content['__content__'] = n
          elsif n.is_a?(::Ox::Node)
            content['__content__'] = n.value
          end
        end
        if (ex = h[e.name]).nil?
          h[e.name] = content
        elsif ex.is_a?(Array)
          ex << content
        else
          h[e.name] = [ex, content]
        end
      end
      
      def string_parser?
        true
      end

    end
  end
end
