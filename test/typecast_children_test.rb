require "test_helper"

# Tests typecast_children behavior with StringIO file handling
class TypecastChildrenTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_unwraps_stringio_file
    file = StringIO.new("content")

    assert_same file, typecast_children({"file" => file, "other" => "data"}, [])
  end

  def test_returns_hash_when_file_not_stringio
    result = typecast_children({"file" => "not a stringio", "other" => "data"}, [])

    assert_kind_of Hash, result
    assert_equal "not a stringio", result["file"]
  end

  def test_returns_hash_when_no_file_key
    result = typecast_children({"name" => "value", "other" => "data"}, [])

    assert_kind_of Hash, result
    assert_equal "value", result["name"]
  end

  def test_returns_hash_when_file_is_nil
    result = typecast_children({"file" => nil, "other" => "data"}, [])

    assert_kind_of Hash, result
    assert_nil result["file"]
  end

  def test_stringio_subclass_is_unwrapped
    klass = Class.new(StringIO)
    file = klass.new("data")
    hash = {"file" => file, "other" => "stuff"}
    result = typecast_children(hash, [])

    assert_equal file, result
    assert_kind_of StringIO, result
  end

  def test_exact_stringio_is_unwrapped
    file = StringIO.new("data")
    hash = {"file" => file}
    result = typecast_children(hash, [])

    assert_equal file, result
  end

  def test_with_file_key_containing_integer
    hash = {"file" => 42, "name" => "test"}
    result = typecast_children(hash, [])

    assert_kind_of Hash, result
    assert_equal 42, result["file"]
  end

  def test_uses_bracket_access_for_file
    hash = {"name" => "test", "data" => "value"}
    result = typecast_children(hash, [])

    assert_kind_of Hash, result
    assert_equal "test", result["name"]
  end

  def test_returns_file_not_fetches
    file = StringIO.new("content")
    hash = {"file" => file}
    result = typecast_children(hash, [])

    assert_same file, result
  end
end
