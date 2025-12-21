require "ox" unless defined?(::Ox)

module MultiXml
  module Parsers
    # XML parser using the Ox library (fastest pure-Ruby parser)
    module Ox
      module_function

      def parse_error = ::Ox::ParseError

      def parse(io)
        handler = SaxHandler.new
        ::Ox.sax_parse(handler, io, convert_special: true, skip: :skip_return)
        handler.result
      end

      # SAX event handler that builds a hash tree while parsing
      class SaxHandler
        def initialize
          @stack = []
        end

        def result = @stack.first

        def start_element(name)
          @stack << {} if @stack.empty?
          child = {}
          add_value(name, child)
          @stack << child
        end

        def end_element(_name)
          strip_whitespace_content if current.key?(TEXT_CONTENT_KEY)
          @stack.pop
        end

        def attr(name, value)
          add_value(name, value) unless @stack.empty?
        end

        def text(value) = add_value(TEXT_CONTENT_KEY, value)
        def cdata(value) = add_value(TEXT_CONTENT_KEY, value)

        def error(message, line, column)
          raise ::Ox::ParseError, "#{message} at #{line}:#{column}"
        end

        private

        def current = @stack.last

        def add_value(key, value)
          key = key.to_s
          existing = current[key]
          current[key] = existing ? append_existing(existing, value) : value
        end

        def append_existing(existing, value)
          existing.is_a?(Array) ? existing << value : [existing, value]
        end

        def strip_whitespace_content
          content = current[TEXT_CONTENT_KEY]
          current.delete(TEXT_CONTENT_KEY) if content.empty? || (current.size > 1 && content.strip.empty?)
        end
      end
    end
  end
end
