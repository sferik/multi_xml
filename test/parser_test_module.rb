require "mutant/minitest/coverage"

module ParserTests
  def self.included(base)
    base.extend(Mutant::Minitest::Coverage)
    base.cover("MultiXml*")
  end

  def setup
    MultiXml.parser = self.class::PARSER

    LibXML::XML::Error.set_handler(&LibXML::XML::Error::QUIET_HANDLER) if %w[LibXML libxml_sax].include?(self.class::PARSER)
  rescue LoadError
    skip "Parser #{self.class::PARSER} couldn't be loaded"
  end

  def test_blank_string_returns_empty_hash
    assert_empty(MultiXml.parse(""))
  end

  def test_whitespace_string_returns_empty_hash
    assert_empty(MultiXml.parse(" "))
  end

  def test_frozen_whitespace_string_returns_empty_hash
    assert_empty(MultiXml.parse(" ".freeze))
  end

  def test_invalid_xml_raises_parse_error
    skip if self.class::PARSER == "Oga"
    assert_raises(MultiXml::ParseError) { MultiXml.parse("<open></close>") }
  end

  def test_invalid_xml_includes_original_xml_in_exception
    skip if self.class::PARSER == "Oga"
    xml = "<open></close>"
    MultiXml.parse(xml)
  rescue MultiXml::ParseError => e
    assert_equal xml, e.xml
  end

  def test_invalid_xml_includes_underlying_cause_in_exception
    skip if self.class::PARSER == "Oga"
    MultiXml.parse("<open></close>")
  rescue MultiXml::ParseError => e
    refute_nil e.cause
  end

  def test_valid_xml_parses_correctly
    assert_equal({"user" => nil}, MultiXml.parse("<user/>"))
  end

  def test_cdata_returns_correct_content
    assert_equal "Erik Berlin", MultiXml.parse("<user><![CDATA[Erik Berlin]]></user>")["user"]
  end

  def test_preserves_whitespace_when_no_children_or_attributes
    assert_equal " ", MultiXml.parse("<tag> </tag>")["tag"]
  end

  def test_preserves_multiple_spaces_when_no_children_or_attributes
    assert_equal "   ", MultiXml.parse("<tag>   </tag>")["tag"]
  end

  def test_preserves_newlines_and_tabs_when_no_children_or_attributes
    assert_equal "\n\t\n", MultiXml.parse("<tag>\n\t\n</tag>")["tag"]
  end

  def test_strips_whitespace_when_there_are_child_elements
    assert_equal({"child" => nil}, MultiXml.parse("<tag> <child/> </tag>")["tag"])
  end

  def test_strips_whitespace_when_there_are_attributes
    assert_equal({"attr" => "val"}, MultiXml.parse('<tag attr="val"> </tag>')["tag"])
  end

  def test_preserves_content_with_surrounding_whitespace
    assert_equal "  hello  ", MultiXml.parse("<tag>  hello  </tag>")["tag"]
  end

  def test_element_with_same_inner_element_and_attribute_name_returns_array
    assert_equal %w[John Smith], MultiXml.parse("<user name='John'><name>Smith</name></user>")["user"]["name"]
  end

  def test_content_returns_correct_value
    assert_equal "Erik Berlin", MultiXml.parse("<user>Erik Berlin</user>")["user"]
  end

  def test_attribute_returns_correct_value
    assert_equal "Erik Berlin", MultiXml.parse('<user name="Erik Berlin"/>')["user"]["name"]
  end

  def test_multiple_attributes_return_correct_values
    result = MultiXml.parse('<user name="Erik Berlin" screen_name="sferik"/>')["user"]

    assert_equal "Erik Berlin", result["name"]
    assert_equal "sferik", result["screen_name"]
  end

  def test_typecast_xml_value_true_typecasts_string_type
    xml = "<global-settings><group><name>Settings</name>" \
          '<setting type="string"><description>Test</description></setting></group></global-settings>'
    setting = MultiXml.parse(xml)["global_settings"]["group"]["setting"]

    assert_equal "", setting
  end

  def test_typecast_xml_value_false_preserves_type_attribute
    xml = "<global-settings><group><name>Settings</name>" \
          '<setting type="string"><description>Test</description></setting></group></global-settings>'
    setting = MultiXml.parse(xml, typecast_xml_value: false)["global_settings"]["group"]["setting"]

    assert_equal({"type" => "string", "description" => {"__content__" => "Test"}}, setting)
  end

  def test_symbolize_keys_option
    xml = '<users><user name="Erik Berlin"/><user><name>Wynn Netherland</name></user></users>'
    expected = {users: {user: [{name: "Erik Berlin"}, {name: "Wynn Netherland"}]}}

    assert_equal expected, MultiXml.parse(xml, symbolize_keys: true)
  end

  def test_boolean_true_returns_true
    assert MultiXml.parse('<tag type="boolean">true</tag>')["tag"]
  end

  def test_boolean_false_returns_false
    refute MultiXml.parse('<tag type="boolean">false</tag>')["tag"]
  end

  def test_boolean_1_returns_true
    assert MultiXml.parse('<tag type="boolean">1</tag>')["tag"]
  end

  def test_boolean_0_returns_false
    refute MultiXml.parse('<tag type="boolean">0</tag>')["tag"]
  end

  def test_integer_returns_positive_integer
    result = MultiXml.parse('<tag type="integer">1</tag>')["tag"]

    assert_kind_of Integer, result
    assert_equal 1, result
  end

  def test_integer_returns_negative_integer
    result = MultiXml.parse('<tag type="integer">-1</tag>')["tag"]

    assert_kind_of Integer, result
    assert_equal(-1, result)
  end

  def test_string_type_returns_string
    result = MultiXml.parse('<tag type="string"></tag>')["tag"]

    assert_kind_of String, result
    assert_equal "", result
  end

  def test_date_type_returns_date
    result = MultiXml.parse('<tag type="date">1970-01-01</tag>')["tag"]

    assert_kind_of Date, result
    assert_equal Date.parse("1970-01-01"), result
  end

  def test_datetime_type_returns_time
    result = MultiXml.parse('<tag type="datetime">1970-01-01 00:00</tag>')["tag"]

    assert_kind_of Time, result
    assert_equal Time.parse("1970-01-01 00:00"), result
  end

  def test_date_time_type_returns_time
    result = MultiXml.parse('<tag type="dateTime">1970-01-01 00:00</tag>')["tag"]

    assert_kind_of Time, result
    assert_equal Time.parse("1970-01-01 00:00"), result
  end

  def test_double_type_returns_float
    result = MultiXml.parse('<tag type="double">3.14159265358979</tag>')["tag"]

    assert_kind_of Float, result
    assert_in_delta(3.14159265358979, result)
  end

  def test_decimal_type_returns_bigdecimal
    result = MultiXml.parse('<tag type="decimal">3.14159265358979</tag>')["tag"]

    assert_kind_of BigDecimal, result
    assert_in_delta(3.14159265358979, result)
  end

  def test_base64binary_type_returns_decoded_string
    result = MultiXml.parse('<tag type="base64Binary">aW1hZ2UucG5n</tag>')["tag"]

    assert_kind_of String, result
    assert_equal "image.png", result
  end

  def test_yaml_type_raises_disallowed_type_error_by_default
    xml = "<tag type=\"yaml\">--- \n1: returns an integer\n:message: Have a nice day\n" \
          "array: \n- has-dashes: true\n  has_underscores: true\n</tag>"
    assert_raises(MultiXml::DisallowedTypeError) { MultiXml.parse(xml)["tag"] }
  end

  def test_yaml_type_returns_parsed_yaml_when_allowed
    xml = "<tag type=\"yaml\">--- \n1: returns an integer\n:message: Have a nice day\n" \
          "array: \n- has-dashes: true\n  has_underscores: true\n</tag>"
    expected = {:message => "Have a nice day", 1 => "returns an integer",
                "array" => [{"has-dashes" => true, "has_underscores" => true}]}

    assert_equal expected, MultiXml.parse(xml, disallowed_types: [])["tag"]
  end

  def test_symbol_type_raises_disallowed_type_error
    assert_raises(MultiXml::DisallowedTypeError) { MultiXml.parse('<tag type="symbol">my_symbol</tag>')["tag"] }
  end

  def test_symbol_type_returns_symbol_when_allowed
    assert_equal :my_symbol, MultiXml.parse('<tag type="symbol">my_symbol</tag>', disallowed_types: [])["tag"]
  end

  def test_file_type_returns_stringio
    xml = '<tag type="file" name="data.txt" content_type="text/plain">ZGF0YQ==</tag>'
    result = MultiXml.parse(xml)["tag"]

    assert_kind_of StringIO, result
    assert_equal "data", result.string
    assert_equal "data.txt", result.original_filename
    assert_equal "text/plain", result.content_type
  end

  def test_file_type_with_missing_name_and_content_type
    xml = '<tag type="file">ZGF0YQ==</tag>'
    result = MultiXml.parse(xml)["tag"]

    assert_kind_of StringIO, result
    assert_equal "data", result.string
    assert_equal "untitled", result.original_filename
    assert_equal "application/octet-stream", result.content_type
  end

  def test_array_type_returns_array
    xml = '<users type="array"><user>Erik Berlin</user><user>Wynn Netherland</user></users>'
    result = MultiXml.parse(xml)["users"]

    assert_kind_of Array, result
    assert_equal ["Erik Berlin", "Wynn Netherland"], result
  end

  def test_array_type_with_other_attributes_returns_array
    xml = '<users type="array" foo="bar"><user>Erik Berlin</user><user>Wynn Netherland</user></users>'
    result = MultiXml.parse(xml)["users"]

    assert_kind_of Array, result
    assert_equal ["Erik Berlin", "Wynn Netherland"], result
  end

  def test_array_type_with_single_item_returns_array
    xml = '<users type="array"><user>Erik Berlin</user></users>'
    result = MultiXml.parse(xml)["users"]

    assert_kind_of Array, result
    assert_equal ["Erik Berlin"], result
  end

  def test_empty_integer_returns_nil
    assert_nil MultiXml.parse('<tag type="integer"/>')["tag"]
  end

  def test_empty_boolean_returns_nil
    assert_nil MultiXml.parse('<tag type="boolean"/>')["tag"]
  end

  def test_empty_date_returns_nil
    assert_nil MultiXml.parse('<tag type="date"/>')["tag"]
  end

  def test_empty_datetime_returns_nil
    assert_nil MultiXml.parse('<tag type="datetime"/>')["tag"]
  end

  def test_empty_file_returns_nil
    assert_nil MultiXml.parse('<tag type="file"/>')["tag"]
  end

  def test_empty_yaml_raises_disallowed_type_error
    assert_raises(MultiXml::DisallowedTypeError) { MultiXml.parse('<tag type="yaml"/>')["tag"] }
  end

  def test_empty_yaml_returns_nil_when_allowed
    assert_nil MultiXml.parse('<tag type="yaml"/>', disallowed_types: [])["tag"]
  end

  def test_empty_symbol_raises_disallowed_type_error
    assert_raises(MultiXml::DisallowedTypeError) { MultiXml.parse('<tag type="symbol"/>')["tag"] }
  end

  def test_empty_symbol_returns_nil_when_allowed
    assert_nil MultiXml.parse('<tag type="symbol"/>', disallowed_types: [])["tag"]
  end

  def test_empty_array_returns_empty_array
    assert_empty MultiXml.parse('<tag type="array"/>')["tag"]
  end

  def test_empty_array_with_whitespace_returns_empty_array
    assert_empty MultiXml.parse('<tag type="array"> </tag>')["tag"]
  end

  def test_xml_entities_in_content_are_unescaped
    {"<" => "&lt;", ">" => "&gt;", '"' => "&quot;", "'" => "&apos;", "&" => "&amp;"}.each do |char, entity|
      assert_equal char, MultiXml.parse("<tag>#{entity}</tag>")["tag"]
    end
  end

  def test_xml_entities_in_attribute_are_unescaped
    {"<" => "&lt;", ">" => "&gt;", '"' => "&quot;", "'" => "&apos;", "&" => "&amp;"}.each do |char, entity|
      assert_equal char, MultiXml.parse("<tag attribute=\"#{entity}\"/>")["tag"]["attribute"]
    end
  end

  def test_dasherized_tag_is_undasherized
    assert_includes MultiXml.parse("<tag-1/>").keys, "tag_1"
  end

  def test_dasherized_attribute_is_undasherized
    assert_includes MultiXml.parse('<tag attribute-1="1"></tag>')["tag"].keys, "attribute_1"
  end

  def test_children_with_attributes_return_correct_values
    xml = '<users><user name="Erik Berlin"/></users>'

    assert_equal "Erik Berlin", MultiXml.parse(xml)["users"]["user"]["name"]
  end

  def test_children_with_text_return_correct_values
    xml = "<user><name>Erik Berlin</name></user>"

    assert_equal "Erik Berlin", MultiXml.parse(xml)["user"]["name"]
  end

  def test_children_with_unrecognized_type_attribute_passes_through
    xml = '<user type="admin"><name>Erik Berlin</name></user>'

    assert_equal "admin", MultiXml.parse(xml)["user"]["type"]
  end

  def test_children_with_non_type_attribute_tags_on_content_nodes
    xml = "<options><value currency='USD'>123</value><value number='percent'>0.123</value></options>"
    values = MultiXml.parse(xml)["options"]["value"]

    assert_equal "123", values[0]["__content__"]
    assert_equal "USD", values[0]["currency"]
    assert_equal "0.123", values[1]["__content__"]
    assert_equal "percent", values[1]["number"]
  end

  def test_children_with_unrecognized_type_attribute_tags_on_content_nodes_first_value
    xml = "<options><value type='USD'>123</value><value type='percent'>0.123</value><value currency='USD'>123</value></options>"
    values = MultiXml.parse(xml)["options"]["value"]

    assert_equal "123", values[0]["__content__"]
    assert_equal "USD", values[0]["type"]
  end

  def test_children_with_unrecognized_type_attribute_tags_on_content_nodes_second_value
    xml = "<options><value type='USD'>123</value><value type='percent'>0.123</value><value currency='USD'>123</value></options>"
    values = MultiXml.parse(xml)["options"]["value"]

    assert_equal "0.123", values[1]["__content__"]
    assert_equal "percent", values[1]["type"]
  end

  def test_children_with_unrecognized_type_attribute_tags_on_content_nodes_third_value
    xml = "<options><value type='USD'>123</value><value type='percent'>0.123</value><value currency='USD'>123</value></options>"
    values = MultiXml.parse(xml)["options"]["value"]

    assert_equal "123", values[2]["__content__"]
    assert_equal "USD", values[2]["currency"]
  end

  def test_children_mixing_attributes_and_non_attributes_first_value
    xml = "<options><value type='USD'>123</value><value type='percent'>0.123</value><value>123</value></options>"
    values = MultiXml.parse(xml)["options"]["value"]

    assert_equal "123", values[0]["__content__"]
    assert_equal "USD", values[0]["type"]
  end

  def test_children_mixing_attributes_and_non_attributes_second_value
    xml = "<options><value type='USD'>123</value><value type='percent'>0.123</value><value>123</value></options>"
    values = MultiXml.parse(xml)["options"]["value"]

    assert_equal "0.123", values[1]["__content__"]
    assert_equal "percent", values[1]["type"]
  end

  def test_children_mixing_attributes_and_non_attributes_third_value
    xml = "<options><value type='USD'>123</value><value type='percent'>0.123</value><value>123</value></options>"
    values = MultiXml.parse(xml)["options"]["value"]

    assert_equal "123", values[2]
  end

  def test_children_mixing_recognized_type_attribute_and_non_type_attributes
    xml = "<options><value number='USD' type='integer'>123</value></options>"
    result = MultiXml.parse(xml)["options"]["value"]

    assert_equal 123, result["__content__"]
    assert_equal "USD", result["number"]
  end

  def test_children_mixing_unrecognized_type_attribute_and_non_type_attributes
    xml = "<options><value number='USD' type='currency'>123</value></options>"
    result = MultiXml.parse(xml)["options"]["value"]

    assert_equal "123", result["__content__"]
    assert_equal "USD", result["number"]
    assert_equal "currency", result["type"]
  end

  def test_children_with_newlines_and_whitespace_parse_correctly
    xml = "<user>\n  <name>Erik Berlin</name>\n</user>"

    assert_equal({"user" => {"name" => "Erik Berlin"}}, MultiXml.parse(xml))
  end

  def test_nested_children_parse_correctly
    xml = '<users><user name="Erik Berlin"><status text="Hello"/></user></users>'
    expected = {"users" => {"user" => {"name" => "Erik Berlin", "status" => {"text" => "Hello"}}}}

    assert_equal expected, MultiXml.parse(xml)
  end

  def test_sibling_children_return_array
    xml = "<users><user>Erik Berlin</user><user>Wynn Netherland</user></users>"

    assert_kind_of Array, MultiXml.parse(xml)["users"]["user"]
  end

  def test_sibling_children_parse_correctly
    xml = "<users><user>Erik Berlin</user><user>Wynn Netherland</user></users>"
    expected = {"users" => {"user" => ["Erik Berlin", "Wynn Netherland"]}}

    assert_equal expected, MultiXml.parse(xml)
  end

  def test_duplexed_stream_parses_correctly
    rd, wr = IO.pipe
    Thread.new do
      "<user/>".each_char do |chunk|
        wr << chunk
      end
      wr.close
    end

    assert_equal({"user" => nil}, MultiXml.parse(rd))
  end
end
