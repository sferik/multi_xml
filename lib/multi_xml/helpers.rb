module MultiXml
  # Methods for transforming parsed XML hash structures
  module Helpers
    module_function

    # Recursively convert all hash keys to symbols
    def symbolize_keys(data)
      case data
      when Hash then data.transform_keys(&:to_sym).transform_values { |v| symbolize_keys(v) }
      when Array then data.map { |item| symbolize_keys(item) }
      else data
      end
    end

    # Recursively convert dashes in hash keys to underscores
    def undasherize_keys(data)
      case data
      when Hash then data.transform_keys { |k| k.tr("-", "_") }.transform_values { |v| undasherize_keys(v) }
      when Array then data.map { |item| undasherize_keys(item) }
      else data
      end
    end

    # Recursively typecast XML values based on type attributes
    def typecast_xml_value(value, disallowed_types = DISALLOWED_TYPES)
      case value
      when Hash then typecast_hash(value, disallowed_types)
      when Array then typecast_array(value, disallowed_types)
      else value
      end
    end

    def typecast_array(array, disallowed_types)
      array.map! { |item| typecast_xml_value(item, disallowed_types) }
      array.one? ? array.first : array
    end

    def typecast_hash(hash, disallowed_types)
      type = hash["type"]
      raise DisallowedTypeError, type if disallowed_type?(type, disallowed_types)

      convert_hash(hash, type, disallowed_types)
    end

    def disallowed_type?(type, disallowed_types)
      type && !type.is_a?(Hash) && disallowed_types.include?(type)
    end

    def convert_hash(hash, type, disallowed_types)
      return extract_array_entries(hash, disallowed_types) if type == "array"
      return convert_text_content(hash) if hash.key?(TEXT_CONTENT_KEY)
      return "" if type == "string" && hash["nil"] != "true"
      return nil if empty_value?(hash, type)

      typecast_children(hash, disallowed_types)
    end

    def typecast_children(hash, disallowed_types)
      result = hash.transform_values { |v| typecast_xml_value(v, disallowed_types) }
      # Unwrap single file element for HTML multipart compatibility
      result["file"].is_a?(StringIO) ? result["file"] : result
    end

    # Extract array entries from element with type="array"
    # See: https://github.com/jnunemaker/httparty/issues/102
    def extract_array_entries(hash, disallowed_types)
      _, entries = hash.find { |k, v| k != "type" && (v.is_a?(Array) || v.is_a?(Hash)) }

      case entries
      when Array then entries.map { |e| typecast_xml_value(e, disallowed_types) }
      when Hash then [typecast_xml_value(entries, disallowed_types)]
      else []
      end
    end

    def convert_text_content(hash)
      content = hash[TEXT_CONTENT_KEY]
      converter = TYPE_CONVERTERS[hash["type"]]

      return unwrap_if_simple(hash, content) unless converter

      # Binary converters need access to entity attributes (e.g., encoding, name)
      return converter.call(content, hash) if converter.arity == 2

      hash.delete("type")
      unwrap_if_simple(hash, converter.call(content))
    end

    def unwrap_if_simple(hash, value)
      (hash.size > 1) ? hash.merge(TEXT_CONTENT_KEY => value) : value
    end

    def empty_value?(hash, type)
      hash.empty? ||
        hash["nil"] == "true" ||
        (type && hash.size == 1 && !type.is_a?(Hash))
    end
  end
end
