module MultiXml
  # Hash key for storing text content within element hashes
  #
  # @api public
  # @return [String] the key "__content__" used for text content
  # @example Accessing text content
  #   result = MultiXml.parse('<name>John</name>')
  #   result["name"] #=> "John" (simplified, but internally uses __content__)
  TEXT_CONTENT_KEY = "__content__".freeze

  # Maps Ruby class names to XML type attribute values
  #
  # @api public
  # @return [Hash{String => String}] mapping of Ruby class names to XML types
  # @example Check XML type for a Ruby class
  #   RUBY_TYPE_TO_XML["Integer"] #=> "integer"
  RUBY_TYPE_TO_XML = {
    "Symbol" => "symbol",
    "Integer" => "integer",
    "BigDecimal" => "decimal",
    "Float" => "float",
    "TrueClass" => "boolean",
    "FalseClass" => "boolean",
    "Date" => "date",
    "DateTime" => "datetime",
    "Time" => "datetime",
    "Array" => "array",
    "Hash" => "hash"
  }.freeze

  # XML type attributes disallowed by default for security
  #
  # These types are blocked to prevent code execution vulnerabilities.
  #
  # @api public
  # @return [Array<String>] list of disallowed type names
  # @example Check default disallowed types
  #   DISALLOWED_TYPES #=> ["symbol", "yaml"]
  DISALLOWED_TYPES = %w[symbol yaml].freeze

  # Values that represent false in XML boolean attributes
  #
  # @api public
  # @return [Array<String>] values considered false
  # @example Check false values
  #   FALSE_BOOLEAN_VALUES.include?("0") #=> true
  FALSE_BOOLEAN_VALUES = %w[0 false].freeze

  # Default parsing options
  #
  # @api public
  # @return [Hash] default options for parse method
  # @example View defaults
  #   DEFAULT_OPTIONS[:symbolize_keys] #=> false
  DEFAULT_OPTIONS = {
    typecast_xml_value: true,
    disallowed_types: DISALLOWED_TYPES,
    symbolize_keys: false
  }.freeze

  # Parser libraries in preference order (fastest first)
  #
  # @api public
  # @return [Array<Array>] pairs of [require_path, parser_symbol]
  # @example View parser order
  #   PARSER_PREFERENCE.first #=> ["ox", :ox]
  PARSER_PREFERENCE = [
    ["ox", :ox],
    ["libxml", :libxml],
    ["nokogiri", :nokogiri],
    ["rexml/document", :rexml],
    ["oga", :oga]
  ].freeze

  # Parses datetime strings, trying Time first then DateTime
  #
  # @api private
  # @return [Proc] lambda that parses datetime strings
  PARSE_DATETIME = lambda do |s|
    Time.parse(s).utc
  rescue ArgumentError
    DateTime.parse(s).to_time.utc
  end.freeze

  # Type converters for XML type attributes
  #
  # Maps type attribute values to lambdas that convert string content.
  # Converters with arity 2 receive the content and the full entity hash.
  #
  # @api public
  # @return [Hash{String => Proc}] mapping of type names to converter procs
  # @example Using a converter
  #   TYPE_CONVERTERS["integer"].call("42") #=> 42
  TYPE_CONVERTERS = {
    "symbol" => ->(s) { s.to_sym },
    "date" => ->(s) { Date.parse(s) },
    "datetime" => PARSE_DATETIME,
    "dateTime" => PARSE_DATETIME,
    "integer" => ->(s) { s.to_i },
    "float" => ->(s) { s.to_f },
    "double" => ->(s) { s.to_f },
    "decimal" => ->(s) { BigDecimal(s) },
    "boolean" => ->(s) { !FALSE_BOOLEAN_VALUES.include?(s.strip) },
    "string" => ->(s) { s.to_s },
    "yaml" => lambda do |s|
      YAML.safe_load(s, permitted_classes: [Symbol, Date, Time])
    rescue ArgumentError, Psych::SyntaxError
      s
    end,
    "base64Binary" => ->(s) { s.unpack1("m") },
    "binary" => ->(s, entity) { (entity["encoding"] == "base64") ? s.unpack1("m") : s },
    "file" => lambda do |s, entity|
      StringIO.new(s.unpack1("m")).tap do |io|
        io.extend(FileLike)
        io.original_filename = entity["name"]
        io.content_type = entity["content_type"]
      end
    end
  }.freeze
end
