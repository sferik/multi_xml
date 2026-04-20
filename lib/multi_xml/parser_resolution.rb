module MultiXml
  # Internal helpers for resolving and loading parser backends
  #
  # @api private
  module ParserResolution
    private

    # Resolve a parser specification to a module
    #
    # @api private
    # @param spec [Symbol, String, Class, Module] Parser specification
    # @return [Module] Resolved parser module
    # @raise [RuntimeError] if spec is invalid
    def resolve_parser(spec)
      case spec
      when String, Symbol then load_parser(spec)
      when Module then spec
      else raise "Invalid parser specification: expected Symbol, String, or Module"
      end
    end

    # Load a parser by name
    #
    # @api private
    # @param name [Symbol, String] Parser name
    # @return [Module] Loaded parser module
    def load_parser(name)
      name = name.to_s.downcase
      require "multi_xml/parsers/#{name}"
      Parsers.const_get(camelize(name))
    end

    # Convert underscored string to CamelCase
    #
    # @api private
    # @param name [String] Underscored string
    # @return [String] CamelCased string
    def camelize(name)
      name.split("_").map(&:capitalize).join
    end

    # Detect the best available parser
    #
    # @api private
    # @return [Symbol] Parser name
    # @raise [NoParserError] if no parser is available
    def detect_parser
      find_loaded_parser || find_available_parser || raise_no_parser_error
    end

    # Parser constant names mapped to their symbols, in preference order
    #
    # @api private
    LOADED_PARSER_CHECKS = {
      Ox: :ox,
      LibXML: :libxml,
      Nokogiri: :nokogiri,
      Oga: :oga
    }.freeze
    private_constant :LOADED_PARSER_CHECKS

    # Find an already-loaded parser library
    #
    # @api private
    # @return [Symbol, nil] Parser name or nil if none loaded
    def find_loaded_parser
      LOADED_PARSER_CHECKS.each do |const_name, parser_name|
        return parser_name if Object.const_defined?(const_name)
      end
      nil
    end

    # Try to load and find an available parser
    #
    # @api private
    # @return [Symbol, nil] Parser name or nil if none available
    def find_available_parser
      PARSER_PREFERENCE.each do |library, parser_name|
        return parser_name if try_require(library)
      end
      nil
    end

    # Attempt to require a library
    #
    # @api private
    # @param library [String] Library to require
    # @return [Boolean] true if successful, false if LoadError
    def try_require(library)
      require library
      true
    rescue LoadError
      false
    end

    # Raise an error indicating no parser is available
    #
    # @api private
    # @return [void]
    # @raise [NoParserError] always
    def raise_no_parser_error
      raise NoParserError, <<~MSG.chomp
        No XML parser detected. Install one of: ox, nokogiri, libxml-ruby, or oga.
        See https://github.com/sferik/multi_xml for more information.
      MSG
    end
  end
end
