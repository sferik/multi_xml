module MultiXml
  unless defined?(PARSING)
    float_proc = proc { |float| float.to_f }
    datetime_proc = proc { |time|
      begin
        Time.parse(time).utc
      rescue StandardError
        DateTime.parse(time).utc
      end
    }

    PARSING = {
      "symbol" => proc { |symbol| symbol.to_sym },
      "date" => proc { |date| Date.parse(date) },
      "datetime" => datetime_proc,
      "dateTime" => datetime_proc,
      "integer" => proc { |integer| integer.to_i },
      "float" => float_proc,
      "double" => float_proc,
      "decimal" => proc { |number| BigDecimal(number) },
      "boolean" => proc { |boolean| !%w[0 false].include?(boolean.strip) },
      "string" => proc { |string| string.to_s },
      "yaml" => proc { |yaml|
        begin
          YAML.load(yaml)
        rescue StandardError
          yaml
        end
      },
      "base64Binary" => proc { |binary| Helpers.base64_decode(binary) },
      "binary" => proc { |binary, entity| Helpers.parse_binary(binary, entity) },
      "file" => proc { |file, entity| Helpers.parse_file(file, entity) }
    }.freeze
  end
end
