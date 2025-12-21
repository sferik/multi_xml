module MultiXml
  # Internal helper methods for XML parsing and typecasting
  module Helpers # :nodoc:
    module_function

    def symbolize_keys(params)
      case params
      when Hash
        params.transform_keys(&:to_sym).transform_values { |v| symbolize_keys(v) }
      when Array
        params.map { |value| symbolize_keys(value) }
      else
        params
      end
    end

    def undasherize_keys(params)
      case params
      when Hash
        params.transform_keys { |key| key.to_s.tr("-", "_") }.transform_values { |v| undasherize_keys(v) }
      when Array
        params.map { |value| undasherize_keys(value) }
      else
        params
      end
    end

    # TODO: Add support for other encodings
    def parse_binary(binary, entity) # :nodoc:
      case entity["encoding"]
      when "base64"
        base64_decode(binary)
      else
        binary
      end
    end

    def parse_file(file, entity)
      f = StringIO.new(base64_decode(file))
      f.extend(FileLike)
      f.original_filename = entity["name"]
      f.content_type = entity["content_type"]
      f
    end

    def base64_decode(input)
      input.unpack1("m")
    end

    def typecast_xml_value(value, disallowed_types = nil)
      disallowed_types ||= DISALLOWED_XML_TYPES

      case value
      when Hash then typecast_hash_value(value, disallowed_types)
      when Array then typecast_array_xml_value(value, disallowed_types)
      when String then value
      else raise("can't typecast #{value.class.name}: #{value.inspect}")
      end
    end

    def typecast_array_xml_value(value, disallowed_types)
      value.map! { |i| typecast_xml_value(i, disallowed_types) }
      (value.length > 1) ? value : value.first
    end

    def typecast_hash_value(value, disallowed_types)
      check_disallowed_type!(value, disallowed_types)
      typecast_hash_by_type(value, disallowed_types)
    end

    def check_disallowed_type!(value, disallowed_types)
      return unless value.include?("type") && !value["type"].is_a?(Hash)
      raise(DisallowedTypeError, value["type"]) if disallowed_types.include?(value["type"])
    end

    def typecast_hash_by_type(value, disallowed_types)
      return typecast_array_value(value, disallowed_types) if value["type"] == "array"
      return typecast_content_value(value) if value.key?(CONTENT_ROOT)
      return "" if value["type"] == "string" && value["nil"] != "true"
      return nil if null_value?(value)

      typecast_nested_hash(value, disallowed_types)
    end

    def typecast_nested_hash(value, disallowed_types)
      xml_value = value.transform_values { |v| typecast_xml_value(v, disallowed_types) }
      # Turn {:files => {:file => #<StringIO>} into {:files => #<StringIO>} for HTML multipart compatibility
      xml_value["file"].is_a?(StringIO) ? xml_value["file"] : xml_value
    end

    # Finds array entries, ignoring non-convertible attribute entries.
    # See: https://github.com/jnunemaker/httparty/issues/102
    def typecast_array_value(value, disallowed_types)
      _, entries = value.detect { |k, v| k != "type" && (v.is_a?(Array) || v.is_a?(Hash)) }
      typecast_array_entries(entries, disallowed_types)
    end

    def typecast_array_entries(entries, disallowed_types)
      case entries
      when NilClass, String then []
      when Array then entries.map { |entry| typecast_xml_value(entry, disallowed_types) }
      when Hash then [typecast_xml_value(entries, disallowed_types)]
      else raise("can't typecast #{entries.class.name}: #{entries.inspect}")
      end
    end

    def typecast_content_value(value)
      content = value[CONTENT_ROOT]
      block = PARSING[value["type"]]

      return (value.keys.size > 1) ? value : content unless block
      return block.call(content, value) unless block.arity == 1

      value.delete("type")
      (value.keys.size > 1) ? value.merge(CONTENT_ROOT => block.call(content)) : block.call(content)
    end

    # Returns true if the value should be treated as nil:
    # - Empty hash or explicitly marked as nil
    # - Only contains a type attribute (and type is not a nested Hash)
    def null_value?(value)
      value.empty? ||
        value["nil"] == "true" ||
        (value["type"] && value.size == 1 && !value["type"].is_a?(Hash))
    end
  end
end
