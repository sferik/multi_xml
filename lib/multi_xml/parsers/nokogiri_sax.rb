require "cgi"
require "nokogiri" unless defined?(Nokogiri)
require "stringio"

module MultiXml
  module Parsers
    module NokogiriSax # :nodoc:
      module_function

      def parse_error
        ::Nokogiri::XML::SyntaxError
      end

      def parse(xml)
        xml = StringIO.new(xml) unless xml.respond_to?(:read)

        return {} if xml.eof?

        document = HashBuilder.new
        parser = ::Nokogiri::XML::SAX::Parser.new(document)
        parser.parse(xml)
        document.hash
      end

      # Class that builds a hash while parsing XML using SAX events.
      class HashBuilder < ::Nokogiri::XML::SAX::Document
        CONTENT_KEY = "__content__".freeze

        attr_reader :hash

        def current_hash
          @hash_stack.last
        end

        def start_document
          @hash = {}
          @hash_stack = [@hash]
          @attrs_stack = []
        end

        def end_document
          raise "Parse stack not empty!" if @hash_stack.size > 1
        end

        def error(error_message)
          raise(::Nokogiri::XML::SyntaxError, error_message)
        end

        def start_element(name, attrs = [])
          new_hash = {CONTENT_KEY => +""}

          case current_hash[name]
          when Array then current_hash[name] << new_hash
          when Hash then current_hash[name] = [current_hash[name], new_hash]
          when nil then current_hash[name] = new_hash
          end

          @hash_stack.push(new_hash)
          @attrs_stack.push(attrs)
        end

        def end_element(_name)
          # Remove content if it's empty or whitespace-only
          current_hash.delete(CONTENT_KEY) if current_hash[CONTENT_KEY].strip.empty?

          # Handle attributes after child elements (like the DOM parser)
          # This ensures proper merging when attribute name matches child element name
          @attrs_stack.pop.each do |attr|
            key = attr[0]
            # Decode numeric character references (e.g., &#38; -> &)
            # SAX parsers encode entities differently than DOM parsers
            value = CGI.unescapeHTML(attr[1])
            existing = current_hash[key]
            current_hash[key] = (existing) ? [value, existing] : value
          end

          @hash_stack.pop
        end

        def characters(string)
          current_hash[CONTENT_KEY] << string
        end

        alias_method :cdata_block, :characters
      end
    end
  end
end
