module MultiXml
  # Hash key for storing text content within element hashes
  TEXT_CONTENT_KEY = "__content__".freeze

  # Maps Ruby class names to XML type attribute values
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
  DISALLOWED_TYPES = %w[symbol yaml].freeze

  # Values that represent false in XML boolean attributes
  FALSE_BOOLEAN_VALUES = %w[0 false].freeze

  # Default parsing options
  DEFAULT_OPTIONS = {
    typecast_xml_value: true,
    disallowed_types: DISALLOWED_TYPES,
    symbolize_keys: false
  }.freeze

  # Parser libraries in preference order (fastest first)
  PARSER_PREFERENCE = [
    ["ox", :ox],
    ["libxml", :libxml],
    ["nokogiri", :nokogiri],
    ["rexml/document", :rexml],
    ["oga", :oga]
  ].freeze

  # Parses datetime strings, trying Time first then DateTime
  PARSE_DATETIME = lambda do |s|
    Time.parse(s).utc
  rescue ArgumentError
    DateTime.parse(s).utc
  end.freeze

  # Type converters for XML type attributes
  # Maps type attribute values to lambdas that convert string content
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
