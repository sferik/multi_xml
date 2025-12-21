require "cgi"
require "libxml" unless defined?(::LibXML)
require "stringio"

module MultiXml
  module Parsers
    module LibxmlSax # :nodoc:
      module_function

      def parse_error
        ::LibXML::XML::Error
      end

      def parse(xml)
        xml = StringIO.new(xml) unless xml.respond_to?(:read)

        return {} if xml.eof?

        LibXML::XML::Error.set_handler(&LibXML::XML::Error::QUIET_HANDLER)
        document = HashBuilder.new
        parser = ::LibXML::XML::SaxParser.io(xml)
        parser.callbacks = document
        parser.parse
        document.hash
      end

      # Class that builds a hash while parsing XML using SAX events.
      class HashBuilder
        include ::LibXML::XML::SaxParser::Callbacks

        CONTENT_KEY = "__content__".freeze

        attr_reader :hash

        def current_hash
          @hash_stack.last
        end

        def on_start_document
          @hash = {}
          @hash_stack = [@hash]
          @attrs_stack = []
          @error = nil
        end

        def on_end_document
          raise @error if @error
        end

        def on_error(error)
          @error = ::LibXML::XML::Error.new(error)
        end

        def on_start_element(name, attrs = {})
          new_hash = {CONTENT_KEY => +""}

          case current_hash[name]
          when Array then current_hash[name] << new_hash
          when Hash then current_hash[name] = [current_hash[name], new_hash]
          when nil then current_hash[name] = new_hash
          end

          @hash_stack.push(new_hash)
          @attrs_stack.push(attrs)
        end

        def on_end_element(_name)
          merge_attrs_into_hash(@attrs_stack.pop)
          remove_empty_content
          @hash_stack.pop
        end

        def merge_attrs_into_hash(attrs)
          attrs.each do |key, value|
            value = CGI.unescapeHTML(value)
            existing = current_hash[key]
            current_hash[key] = existing ? [value, existing] : value
          end
        end

        def remove_empty_content
          content = current_hash[CONTENT_KEY]
          current_hash.delete(CONTENT_KEY) if content.empty? || (current_hash.length > 1 && content.strip.empty?)
        end

        def on_characters(string)
          current_hash[CONTENT_KEY] << string
        end

        alias_method :on_cdata_block, :on_characters
      end
    end
  end
end
