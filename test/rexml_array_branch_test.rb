require "test_helper"

# Tests REXML parser add_to_hash behavior
class RexmlArrayBranchTest < Minitest::Test
  cover "MultiXml*"

  def test_add_to_hash_wraps_array_value_in_array
    require "multi_xml/parsers/rexml"

    hash = {}
    value = %w[item1 item2]
    result = MultiXml::Parsers::Rexml.send(:add_to_hash, hash, "key", value)

    assert_equal [%w[item1 item2]], result["key"]
  end
end
