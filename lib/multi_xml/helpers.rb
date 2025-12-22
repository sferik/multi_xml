module MultiXml
  # Methods for transforming parsed XML hash structures
  #
  # These helper methods handle key transformation and type casting
  # of parsed XML data structures.
  #
  # @api public
  module Helpers
    module_function

    # Recursively convert all hash keys to symbols
    #
    # @api private
    # @param data [Hash, Array, Object] Data to transform
    # @return [Hash, Array, Object] Transformed data with symbolized keys
    # @example Symbolize hash keys
    #   symbolize_keys({"name" => "John"}) #=> {name: "John"}
    def symbolize_keys(data)
      case data
      when Hash then data.transform_keys(&:to_sym).transform_values { |v| symbolize_keys(v) }
      when Array then data.map { |item| symbolize_keys(item) }
      else data
      end
    end

    # Recursively convert dashes in hash keys to underscores
    #
    # @api private
    # @param data [Hash, Array, Object] Data to transform
    # @return [Hash, Array, Object] Transformed data with undasherized keys
    # @example Convert dashed keys
    #   undasherize_keys({"first-name" => "John"}) #=> {"first_name" => "John"}
    def undasherize_keys(data)
      case data
      when Hash then data.transform_keys { |k| k.tr("-", "_") }.transform_values { |v| undasherize_keys(v) }
      when Array then data.map { |item| undasherize_keys(item) }
      else data
      end
    end

    # Recursively typecast XML values based on type attributes
    #
    # @api private
    # @param value [Hash, Array, Object] Value to typecast
    # @param disallowed_types [Array<String>] Types to reject
    # @return [Object] Typecasted value
    # @raise [DisallowedTypeError] if a disallowed type is encountered
    # @example Typecast integer value
    #   typecast_xml_value({"__content__" => "42", "type" => "integer"})
    #   #=> 42
    def typecast_xml_value(value, disallowed_types = DISALLOWED_TYPES)
      case value
      when Hash then typecast_hash(value, disallowed_types)
      when Array then typecast_array(value, disallowed_types)
      else value
      end
    end

    # Typecast array elements and unwrap single-element arrays
    #
    # @api private
    # @param array [Array] Array to typecast
    # @param disallowed_types [Array<String>] Types to reject
    # @return [Object, Array] Typecasted array or single element
    def typecast_array(array, disallowed_types)
      array.map! { |item| typecast_xml_value(item, disallowed_types) }
      array.one? ? array.first : array
    end

    # Typecast a hash based on its type attribute
    #
    # @api private
    # @param hash [Hash] Hash to typecast
    # @param disallowed_types [Array<String>] Types to reject
    # @return [Object] Typecasted value
    # @raise [DisallowedTypeError] if type is disallowed
    def typecast_hash(hash, disallowed_types)
      type = hash["type"]
      raise DisallowedTypeError, type if disallowed_type?(type, disallowed_types)

      convert_hash(hash, type, disallowed_types)
    end

    # Check if a type is in the disallowed list
    #
    # @api private
    # @param type [String, nil] Type to check
    # @param disallowed_types [Array<String>] Disallowed type list
    # @return [Boolean] true if type is disallowed
    def disallowed_type?(type, disallowed_types)
      type && !type.is_a?(Hash) && disallowed_types.include?(type)
    end

    # Convert a hash based on its type and content
    #
    # @api private
    # @param hash [Hash] Hash to convert
    # @param type [String, nil] Type attribute value
    # @param disallowed_types [Array<String>] Types to reject
    # @return [Object] Converted value
    def convert_hash(hash, type, disallowed_types)
      return extract_array_entries(hash, disallowed_types) if type == "array"
      return convert_text_content(hash) if hash.key?(TEXT_CONTENT_KEY)
      return "" if type == "string" && hash["nil"] != "true"
      return nil if empty_value?(hash, type)

      typecast_children(hash, disallowed_types)
    end

    # Typecast all child values in a hash
    #
    # @api private
    # @param hash [Hash] Hash with children to typecast
    # @param disallowed_types [Array<String>] Types to reject
    # @return [Hash, StringIO] Typecasted hash or unwrapped file
    def typecast_children(hash, disallowed_types)
      result = hash.transform_values { |v| typecast_xml_value(v, disallowed_types) }
      # Unwrap single file element for HTML multipart compatibility
      result["file"].is_a?(StringIO) ? result["file"] : result
    end

    # Extract array entries from element with type="array"
    #
    # @api private
    # @param hash [Hash] Hash containing array entries
    # @param disallowed_types [Array<String>] Types to reject
    # @return [Array] Extracted and typecasted entries
    # @see https://github.com/jnunemaker/httparty/issues/102
    def extract_array_entries(hash, disallowed_types)
      _, entries = hash.find { |k, v| k != "type" && (v.is_a?(Array) || v.is_a?(Hash)) }

      case entries
      when Array then entries.map { |e| typecast_xml_value(e, disallowed_types) }
      when Hash then [typecast_xml_value(entries, disallowed_types)]
      else []
      end
    end

    # Convert text content using type converters
    #
    # @api private
    # @param hash [Hash] Hash containing text content and type
    # @return [Object] Converted value
    def convert_text_content(hash)
      content = hash[TEXT_CONTENT_KEY]
      converter = TYPE_CONVERTERS[hash["type"]]

      return unwrap_if_simple(hash, content) unless converter

      # Binary converters need access to entity attributes (e.g., encoding, name)
      return converter.call(content, hash) if converter.arity == 2

      hash.delete("type")
      unwrap_if_simple(hash, converter.call(content))
    end

    # Unwrap value if hash has no other significant keys
    #
    # @api private
    # @param hash [Hash] Original hash
    # @param value [Object] Converted value
    # @return [Object, Hash] Value or hash with merged content
    def unwrap_if_simple(hash, value)
      (hash.size > 1) ? hash.merge(TEXT_CONTENT_KEY => value) : value
    end

    # Check if a hash represents an empty value
    #
    # @api private
    # @param hash [Hash] Hash to check
    # @param type [String, nil] Type attribute value
    # @return [Boolean] true if value should be nil
    def empty_value?(hash, type)
      hash.empty? ||
        hash["nil"] == "true" ||
        (type && hash.size == 1 && !type.is_a?(Hash))
    end
  end
end
