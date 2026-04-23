require "test_helper"
require "support/deprecation_helpers"

# Tests the deprecation of the :symbolize_keys option, which was
# renamed to :symbolize_names to match Ruby stdlib's JSON.parse and
# sister library MultiJSON.
class SymbolizeKeysOptionTest < Minitest::Test
  include DeprecationHelpers

  cover "MultiXML*"

  def setup
    reset_deprecation_registry
    stub_kernel_warn
  end

  def teardown
    restore_warn
    restore_deprecation_registry
  end

  def test_no_warning_when_symbolize_keys_absent
    MultiXML.parse("<r>v</r>")
    MultiXML.parse("<r>v</r>", symbolize_names: true)

    refute(@warnings.any? { |w| w.include?(":symbolize_keys option is deprecated") })
  end

  def test_symbolize_keys_option_translates_to_symbolize_names
    result = MultiXML.parse("<root><name>v</name></root>", symbolize_keys: true)

    assert_equal({root: {name: "v"}}, result)
    assert(@warnings.any? { |w| w.include?(":symbolize_keys option is deprecated") })
  end

  def test_symbolize_keys_option_warning_keyed_once
    3.times { MultiXML.parse("<r/>", symbolize_keys: true) }

    matching = @warnings.count { |w| w.include?(":symbolize_keys option is deprecated") }

    assert_equal 1, matching
    assert_includes @shown, :symbolize_keys_option
  end

  def test_symbolize_keys_option_preserves_false_value
    result = MultiXML.parse("<root><name>v</name></root>", symbolize_keys: false)

    assert_equal({"root" => {"name" => "v"}}, result)
  end

  def test_symbolize_keys_option_preserves_true_value
    result = MultiXML.parse("<root><name>v</name></root>", symbolize_keys: true)

    assert_equal({root: {name: "v"}}, result)
  end

  def test_symbolize_keys_option_does_not_mutate_caller_options
    options = {symbolize_keys: true}
    MultiXML.parse("<r>v</r>", options)

    assert_equal({symbolize_keys: true}, options)
  end

  def test_normalize_removes_symbolize_keys_from_returned_options
    normalized = MultiXML::OptionsNormalization.normalize_symbolize_option(symbolize_keys: true, other: 1)

    refute_includes normalized, :symbolize_keys
    assert_equal({symbolize_names: true, other: 1}, normalized)
  end

  def test_symbolize_names_wins_when_both_options_supplied
    result = MultiXML.parse(
      "<root><name>v</name></root>",
      symbolize_keys: false,
      symbolize_names: true
    )

    assert_equal({root: {name: "v"}}, result)
  end
end
