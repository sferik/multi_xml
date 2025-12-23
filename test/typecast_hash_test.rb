require "test_helper"

# Tests typecast_hash type attribute handling
class TypecastHashTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_raises_disallowed_type_error_with_type
    error = assert_raises(MultiXml::DisallowedTypeError) do
      typecast_hash({"type" => "yaml"}, ["yaml"])
    end

    assert_equal "yaml", error.type
  end

  def test_passes_type_to_convert_hash
    hash = {"type" => "array", "item" => %w[a b c]}
    result = typecast_hash(hash, [])

    assert_equal %w[a b c], result
  end

  def test_type_affects_conversion
    hash = {"type" => "string", "nil" => "false"}
    result = typecast_hash(hash, [])

    assert_equal "", result
  end
end
