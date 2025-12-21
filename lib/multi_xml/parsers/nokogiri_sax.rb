require "cgi"
require "nokogiri" unless defined?(::Nokogiri)
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
          merge_attrs_into_hash(@attrs_stack.pop)
          remove_empty_content
          @hash_stack.pop
        end

        def merge_attrs_into_hash(attrs)
          attrs.each do |attr|
            value = CGI.unescapeHTML(attr[1])
            existing = current_hash[attr[0]]
            current_hash[attr[0]] = existing ? [value, existing] : value
          end
        end

        def remove_empty_content
          content = current_hash[CONTENT_KEY]
          current_hash.delete(CONTENT_KEY) if content.empty? || (current_hash.length > 1 && content.strip.empty?)
        end

        def characters(string)
          current_hash[CONTENT_KEY] << string
        end

        alias_method :cdata_block, :characters
      end
    end
  end
end
