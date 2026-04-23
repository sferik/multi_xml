require "test_helper"

# Tests for MultiXML.parse_options / .parse_options= — process-wide
# defaults that merge with DEFAULT_OPTIONS and are overridable at call site.
class ParseOptionsConfigTest < Minitest::Test
  cover "MultiXML*"

  def setup
    @previous = MultiXML.instance_variable_get(:@parse_options)
    MultiXML.instance_variable_set(:@parse_options, nil)
  end

  def teardown
    MultiXML.instance_variable_set(:@parse_options, @previous)
  end

  def test_defaults_to_empty_when_unset
    assert_empty MultiXML.parse_options
  end

  def test_setter_stores_a_hash
    MultiXML.parse_options = {symbolize_names: true}

    assert_equal({symbolize_names: true}, MultiXML.parse_options)
  end

  def test_applies_to_parse_call_without_explicit_option
    MultiXML.parse_options = {symbolize_names: true}

    result = MultiXML.parse("<root><name>v</name></root>")

    assert_equal({root: {name: "v"}}, result)
  end

  def test_call_site_option_wins_over_global_default
    MultiXML.parse_options = {symbolize_names: true}

    result = MultiXML.parse("<root><name>v</name></root>", symbolize_names: false)

    assert_equal({"root" => {"name" => "v"}}, result)
  end

  def test_accepts_callable_returning_hash
    MultiXML.parse_options = -> { {symbolize_names: true} }

    result = MultiXML.parse("<root><name>v</name></root>")

    assert_equal({root: {name: "v"}}, result)
  end

  def test_callable_receives_call_site_options
    received = nil
    MultiXML.parse_options = lambda do |call_site|
      received = call_site
      {}
    end

    MultiXML.parse("<r>v</r>", parser: :rexml)

    assert_equal({parser: :rexml}, received)
  end

  def test_arity_zero_callable_ignores_call_site
    MultiXML.parse_options = -> { {symbolize_names: true} }

    assert_equal({symbolize_names: true}, MultiXML.parse_options(foo: 1))
  end

  def test_unset_returns_frozen_empty_hash
    assert_same MultiXML::Options::EMPTY_OPTIONS, MultiXML.parse_options
  end

  def test_non_hash_non_callable_falls_through_to_empty
    MultiXML.parse_options = Object.new

    assert_empty MultiXML.parse_options
  end

  def test_symbolize_keys_in_global_options_translates_to_symbolize_names
    MultiXML.parse_options = {symbolize_keys: true}

    result = MultiXML.parse("<root><name>v</name></root>")

    assert_equal({root: {name: "v"}}, result)
  end

  def test_to_hash_responder_is_coerced_via_to_hash
    options_obj = Class.new do
      def to_hash = {symbolize_names: true}
    end.new
    MultiXML.parse_options = options_obj

    assert_equal({symbolize_names: true}, MultiXML.parse_options)
  end
end
