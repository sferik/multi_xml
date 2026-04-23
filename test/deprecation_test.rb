require "test_helper"
require "support/deprecation_helpers"

# Tests the deprecation surface: old MultiXml constant access, including
# method delegation and constant lookup. Each path must emit a one-time
# deprecation warning and delegate correctly to MultiXML.
class DeprecationTest < Minitest::Test
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

  def test_multi_xml_constant_parse_delegates_to_multi_xml_module
    result = MultiXml.parse("<a>1</a>")

    assert_equal({"a" => "1"}, result)
    assert(@warnings.any? { |w| w.include?("MultiXml constant is deprecated") })
  end

  def test_multi_xml_constant_respond_to_returns_true_for_known_method
    assert_respond_to MultiXml, :parse
  end

  def test_multi_xml_constant_respond_to_returns_false_for_unknown_method
    refute_respond_to MultiXml, :definitely_not_a_method_name
  end

  def test_multi_xml_constant_method_missing_falls_through_for_unknown
    assert_raises(NoMethodError) { MultiXml.no_such_method }
  end

  def test_multi_xml_constant_const_get_resolves_to_multi_xml_module
    require "multi_xml/parsers/nokogiri"

    assert_equal MultiXML::Parsers::Nokogiri, MultiXml::Parsers::Nokogiri
    assert(@warnings.any? { |w| w.include?("MultiXml constant is deprecated") })
  end

  def test_warn_deprecation_once_tags_category_as_deprecated
    MultiXML.warn_deprecation_once(:probe, "probe message")

    assert_equal "probe message", @warnings.last
    assert_equal :deprecated, @warn_opts.last[:category]
  end

  def test_warn_deprecation_once_skips_repeat_keys
    MultiXML.warn_deprecation_once(:probe, "message one")
    MultiXML.warn_deprecation_once(:probe, "message two")

    assert_equal(1, @warnings.count { |w| w.start_with?("message ") })
  end

  # The sleep gives concurrent threads a real chance of racing past the
  # include? check before either calls add, exposing an unsynchronized
  # warn_deprecation_once.
  def test_warn_deprecation_once_is_thread_safe
    warn_count = 0
    racing_warn = ->(_msg, **) { sleep(0.01) && (warn_count += 1) }
    stub_warn(&racing_warn)
    Array.new(10) { Thread.new { MultiXML.warn_deprecation_once(:race_probe, "msg") } }.each(&:join)

    assert_equal 1, warn_count
  end
end
