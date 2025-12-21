module MultiXml
  unless defined?(REQUIREMENT_MAP)
    REQUIREMENT_MAP = [
      ["ox", :ox],
      ["libxml", :libxml],
      ["nokogiri", :nokogiri],
      ["rexml/document", :rexml],
      ["oga", :oga]
    ].freeze
  end

  CONTENT_ROOT = "__content__".freeze unless defined?(CONTENT_ROOT)

  unless defined?(TYPE_NAMES)
    TYPE_NAMES = {
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
  end

  DISALLOWED_XML_TYPES = %w[symbol yaml].freeze

  DEFAULT_OPTIONS = {
    typecast_xml_value: true,
    disallowed_types: DISALLOWED_XML_TYPES,
    symbolize_keys: false
  }.freeze
end
