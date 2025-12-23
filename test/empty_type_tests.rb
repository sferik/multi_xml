# Tests type coercion of empty/self-closing elements (integer, boolean, date, etc.)
module ParserEmptyTypeTests
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
end
