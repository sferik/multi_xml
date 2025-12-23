require "test_helper"

# Tests extract_array_entries disallowed type propagation
class ExtractArrayEntriesDisallowedTypesTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_passes_disallowed_types_to_array_elements
    hash = {"type" => "array", "item" => [{"type" => "yaml", "__content__" => "test"}]}

    assert_raises(MultiXml::DisallowedTypeError) do
      extract_array_entries(hash, ["yaml"])
    end
  end

  def test_passes_disallowed_types_to_hash_element
    hash = {"type" => "array", "item" => {"type" => "yaml", "__content__" => "test"}}

    assert_raises(MultiXml::DisallowedTypeError) do
      extract_array_entries(hash, ["yaml"])
    end
  end

  def test_hash_branch_uses_custom_disallowed_types_not_default
    # Use "integer" which is NOT in DISALLOWED_TYPES default, so if the mutant
    # removes the disallowed_types argument, it will use the default and NOT raise
    hash = {"type" => "array", "item" => {"type" => "integer", "__content__" => "42"}}

    assert_raises(MultiXml::DisallowedTypeError) do
      extract_array_entries(hash, ["integer"])
    end
  end

  def test_with_custom_disallowed_type_raises
    hash = {"type" => "array", "item" => [{"type" => "integer", "__content__" => "42"}]}

    assert_raises(MultiXml::DisallowedTypeError) do
      extract_array_entries(hash, ["integer"])
    end
  end
end
