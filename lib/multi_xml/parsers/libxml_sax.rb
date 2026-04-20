require "libxml-ruby"
require "stringio"
require_relative "sax_handler"
require_relative "libxml"

module MultiXml
  module Parsers
    # SAX-based parser using LibXML (faster for large documents)
    #
    # @api private
    module LibxmlSax
      module_function

      # Get the parse error class for this parser
      #
      # @api private
      # @return [Class] LibXML::XML::Error
      def parse_error = ::LibXML::XML::Error

      # Parse XML from a string or IO object
      #
      # @api private
      # @param xml [String, IO] XML content
      # @param namespaces [Symbol] Namespace handling mode
      # @return [Hash] Parsed XML as a hash
      # @raise [LibXML::XML::Error] if XML is malformed
      def parse(xml, namespaces: :strip)
        io = xml.respond_to?(:read) ? xml : StringIO.new(xml)
        return {} if io.eof?

        # libxml-ruby's SAX callback strips prefixes from attribute qnames,
        # so we can't reconstruct per-attribute namespace info for non-strip
        # modes. Delegate to the DOM libxml parser in that case; it exposes
        # the namespace metadata we need.
        return Libxml.parse(io, namespaces: namespaces) unless namespaces == :strip

        LibXML::XML::Error.set_handler(&LibXML::XML::Error::QUIET_HANDLER)
        handler = Handler.new(namespaces)
        parser = ::LibXML::XML::SaxParser.io(io)
        parser.callbacks = handler
        parser.parse
        handler.result
      end

      # LibXML SAX handler.
      #
      # libxml-ruby's namespace-aware callback strips prefixes from the attrs
      # hash, so we rely on the qname-preserving `on_start_element` callback
      # and resolve namespaces via SaxHandler's scope stack.
      #
      # @api private
      class Handler
        include ::LibXML::XML::SaxParser::Callbacks
        include SaxHandler

        # Create a new SAX handler
        #
        # @api private
        # @param mode [Symbol] Namespace handling mode
        # @return [Handler] new handler instance
        def initialize(mode)
          initialize_handler(mode)
        end

        # Handle start of document (no-op)
        #
        # @api private
        # @return [void]
        def on_start_document
        end

        # Handle end of document (no-op)
        #
        # @api private
        # @return [void]
        def on_end_document
        end

        # Handle parse errors (no-op; libxml-ruby raises directly)
        #
        # @api private
        # @param _error [String] Error message (unused)
        # @return [void]
        def on_error(_error)
        end

        # Handle start of an element
        #
        # libxml-ruby strips xmlns declarations from attrs and passes through
        # prefixed names for regular attributes. Since libxml_sax only uses
        # this handler in :strip mode, we route through the namespace-aware
        # entrypoint with empty ns_decls and treat attribute qnames as-if
        # they had no namespace — matching the desired :strip output.
        #
        # @api private
        # @param name [String] Element name (possibly prefixed)
        # @param attrs [Hash] Attributes as name => value
        # @return [void]
        def on_start_element(name, attrs = {})
          prefix, local = sax_split_qname(name.to_s)
          tuples = attrs.map do |k, v|
            ap, al = sax_split_qname(k.to_s)
            [ap, al, v]
          end
          handle_start_element_ns(local, prefix, tuples, [])
        end

        # Handle end of an element
        #
        # @api private
        # @param _name [String] Element name (unused)
        # @return [void]
        def on_end_element(_name)
          handle_end_element
        end

        private

        # Split a prefixed name into [prefix, local]
        #
        # @api private
        # @param name [String] Prefixed or local name
        # @return [Array<String, nil>] prefix and local name
        def sax_split_qname(name)
          p, l = name.split(":", 2)
          l ? [p, l] : [nil, p]
        end

        # Handle character data (also aliased as `on_cdata_block`)
        #
        # @api private
        # @param text [String] Text content
        # @return [void]
        def on_characters(text) = append_text(text)
        alias_method :on_cdata_block, :on_characters
      end
    end
  end
end
