# Tests YAML and Symbol type handling, including disallowed_types security option
module ParserYamlSymbolTests
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
end
