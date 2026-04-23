require "test_helper"
require "support/deprecation_helpers"

# Tests the private deprecate_alias helper in lib/multi_xml/deprecated.rb
# directly. The existing alias test (deprecation_test.rb) verifies the
# already-generated `load` method, but mutant patches the helper
# definition at runtime — the methods that were already produced at
# file-load time are unaffected by those mutations. These tests call
# the helper during the test run so the mutated bodies actually execute.
class DeprecateAliasTest < Minitest::Test
  include DeprecationHelpers

  cover "MultiXML*"

  def setup
    @registry = MultiXML.send(:const_get, :DEPRECATION_WARNINGS_SHOWN)
    @original_registry = @registry.dup
    @registry.clear
    @generated = []
    stub_capture_warn
    MultiXML.define_singleton_method(:_dsl_capture) { |*args, **kwargs, &block| [args, kwargs, block&.call] }
    @generated << :_dsl_capture
  end

  def teardown
    restore_warn
    @generated.each { |name| remove_singleton_method(name) }
    @registry.replace(@original_registry)
  end

  def test_defines_a_singleton_method
    name = unique_name
    MultiXML.send(:deprecate_alias, name, :_dsl_capture)

    assert_respond_to MultiXML, name
  end

  def test_forwards_positional_arguments
    name = unique_name
    MultiXML.send(:deprecate_alias, name, :_dsl_capture)

    args, _kwargs, _block = MultiXML.send(name, :a, :b)

    assert_equal %i[a b], args
  end

  def test_forwards_keyword_arguments
    name = unique_name
    MultiXML.send(:deprecate_alias, name, :_dsl_capture)

    _args, kwargs, _block = MultiXML.send(name, foo: 1, bar: 2)

    assert_equal({foo: 1, bar: 2}, kwargs)
  end

  def test_forwards_block
    name = unique_name
    MultiXML.send(:deprecate_alias, name, :_dsl_capture)

    _args, _kwargs, block_value = MultiXML.send(name) { :block_called }

    assert_equal :block_called, block_value
  end

  def test_returns_replacement_value
    name = unique_name
    MultiXML.define_singleton_method(:_dsl_doubled) { |x| x * 2 }
    @generated << :_dsl_doubled
    MultiXML.send(:deprecate_alias, name, :_dsl_doubled)

    assert_equal 14, MultiXML.send(name, 7)
  end

  def test_emits_warning_naming_target_method
    name = unique_name
    MultiXML.send(:deprecate_alias, name, :_dsl_capture)

    MultiXML.send(name)

    assert_includes @captured.first.first, "MultiXML.#{name}"
  end

  def test_emits_warning_naming_replacement
    name = unique_name
    MultiXML.send(:deprecate_alias, name, :_dsl_capture)

    MultiXML.send(name)

    assert_includes @captured.first.first, "MultiXML._dsl_capture"
  end

  def test_warning_mentions_v1_removal
    name = unique_name
    MultiXML.send(:deprecate_alias, name, :_dsl_capture)

    MultiXML.send(name)

    assert_includes @captured.first.first, "v1.0"
  end

  def test_warns_only_once
    name = unique_name
    MultiXML.send(:deprecate_alias, name, :_dsl_capture)

    3.times { MultiXML.send(name) }

    assert_equal 1, @captured.size
  end

  def test_keys_warning_by_alias_name
    name = unique_name
    MultiXML.send(:deprecate_alias, name, :_dsl_capture)

    MultiXML.send(name)

    assert_includes @registry, name
  end

  def test_warning_tagged_as_deprecated_category
    name = unique_name
    MultiXML.send(:deprecate_alias, name, :_dsl_capture)

    MultiXML.send(name)

    assert_equal :deprecated, @captured.first.last[:category]
  end

  private

  def unique_name
    name = :"_dsl_test_#{rand(1 << 30)}"
    @generated << name
    name
  end

  def remove_singleton_method(name)
    sclass = MultiXML.singleton_class
    return unless sclass.method_defined?(name) || sclass.private_method_defined?(name)

    sclass.send(:remove_method, name)
  end

  def stub_capture_warn
    @original_warn = Kernel.method(:warn)
    @captured = []
    captured = @captured
    stub_warn { |msg, **opts| captured << [msg, opts] }
  end
end
