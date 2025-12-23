# Tests type attribute coercion (boolean, integer, date, datetime, decimal, base64)
module ParserTypecastTests
  def test_typecast_xml_value_true_typecasts_string_type
    xml = "<global-settings><group><name>Settings</name>" \
          '<setting type="string"><description>Test</description></setting></group></global-settings>'

    assert_equal "", MultiXml.parse(xml)["global_settings"]["group"]["setting"]
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
end
