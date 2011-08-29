require 'ox' unless defined?(Ox)

module MultiXml
  module Parsers
    module Ox #:nodoc:

      extend self
      
      def parse_error
        ::MultiXml::ParseError
      end

      def parse(xml)
        begin
          doc = ::Ox.parse(xml)
          h = { }
          unless doc.nil?
            element_to_hash(doc, h)
          end
          h
        rescue Exception => e
          puts "*** #{e.class}: #{e.message}"
          raise MultiXml::ParseError(e.message, e.backtrace)
        end
      end

      def element_to_hash(e, h)
        ch = { }
        e.attributes.each do |k,v|
          ch = { } if ch.nil?
          ch[k.to_s] = v
        end
        e.nodes.each do |n|
          if n.is_a?(::Ox::Element)
            k = n.name
            v = ch[k]
            element_to_hash(n, ch)
            if v.nil?
              h[k] = ch
            elsif v.is_a?(Array)
              v << ch
            else
              h[k] = [v, ch]
            end
          elsif n.is_a?(String)
            ch = n
          elsif n.is_a?(::Ox::Node)
            ch = n.value
          end
        end
        v = h[e.name]
        if v.nil?
          h[e.name] = ch
        elsif v.is_a?(Array)
          v << ch unless ch.nil?
        else
          h[e.name] = [v, ch] unless ch.nil?
        end
      end
      
      def string_parser?
        true
      end

      class Error < Exception
      end
    end
  end
end
