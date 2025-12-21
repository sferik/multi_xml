require "cgi"
require "libxml" unless defined?(::LibXML)
require "stringio"

module MultiXml
  module Parsers
    # SAX-based parser using LibXML (faster for large documents)
    module LibxmlSax
      module_function

      def parse_error = ::LibXML::XML::Error

      def parse(xml)
        io = xml.respond_to?(:read) ? xml : StringIO.new(xml)
        return {} if io.eof?

        LibXML::XML::Error.set_handler(&LibXML::XML::Error::QUIET_HANDLER)
        handler = SaxHandler.new
        parser = ::LibXML::XML::SaxParser.io(io)
        parser.callbacks = handler
        parser.parse
        handler.result
      end

      # LibXML SAX handler
      class SaxHandler
        include ::LibXML::XML::SaxParser::Callbacks

        def initialize
          @result = {}
          @stack = [@result]
          @pending_attrs = []
          @error = nil
        end

        def result
          raise @error if @error

          @result
        end

        def on_start_document
        end

        def on_end_document
        end

        def on_error(error)
          @error = ::LibXML::XML::Error.new(error)
        end

        def on_start_element(name, attrs = {})
          push_element(name)
          @pending_attrs << attrs
        end

        def on_end_element(_name)
          apply_attributes(@pending_attrs.pop)
          strip_whitespace_content
          @stack.pop
        end

        def on_characters(text) = append_text(text)
        alias_method :on_cdata_block, :on_characters

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
