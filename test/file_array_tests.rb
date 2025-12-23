# Tests file type (base64 to StringIO) and array type coercion
module ParserFileArrayTests
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
end
