require "cgi"
require "nokogiri" unless defined?(::Nokogiri)
require "stringio"

module MultiXml
  module Parsers
    # SAX-based parser using Nokogiri (faster for large documents)
    module NokogiriSax
      module_function

      def parse_error = ::Nokogiri::XML::SyntaxError

      def parse(xml)
        io = xml.respond_to?(:read) ? xml : StringIO.new(xml)
        return {} if io.eof?

        handler = SaxHandler.new
        ::Nokogiri::XML::SAX::Parser.new(handler).parse(io)
        handler.result
      end

      # Nokogiri SAX handler
      class SaxHandler < ::Nokogiri::XML::SAX::Document
        def initialize
          super
          @result = {}
          @stack = [@result]
          @pending_attrs = []
        end

        attr_reader :result

        def start_document
        end

        def end_document
        end

        def error(message)
          raise ::Nokogiri::XML::SyntaxError, message
        end

        def start_element(name, attrs = [])
          push_element(name)
          @pending_attrs << attrs.to_h
        end

        def end_element(_name)
          apply_attributes(@pending_attrs.pop)
          strip_whitespace_content
          @stack.pop
        end

        def characters(text) = append_text(text)
        alias_method :cdata_block, :characters

        private

        def current = @stack.last

        def push_element(name)
          child = {TEXT_CONTENT_KEY => +""}
          add_value(name, child)
          @stack << child
        end

        def append_text(text)
          current[TEXT_CONTENT_KEY] << text
        end

        def add_value(name, value)
          existing = current[name]
          current[name] = case existing
          when Array then existing << value
          when Hash then [existing, value]
          else value
          end
        end

        def apply_attributes(attrs)
          attrs.each do |name, value|
            value = CGI.unescapeHTML(value)
            existing = current[name]
            current[name] = existing ? [value, existing] : value
          end
        end

        def strip_whitespace_content
          content = current[TEXT_CONTENT_KEY]
          current.delete(TEXT_CONTENT_KEY) if content.empty? || (current.size > 1 && content.strip.empty?)
        end
      end
    end
  end
end
