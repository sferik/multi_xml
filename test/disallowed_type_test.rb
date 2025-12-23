require "test_helper"
require_relative "test_subclasses"

# Tests disallowed_type? checking
class DisallowedTypeTest < Minitest::Test
  cover "MultiXml*"
  include MultiXml::Helpers

  def test_returns_true_for_disallowed
    assert disallowed_type?("yaml", %w[yaml symbol])
  end

  def test_returns_false_for_allowed
    refute disallowed_type?("string", %w[yaml symbol])
  end

  def test_returns_false_for_nil_type
    refute disallowed_type?(nil, %w[yaml symbol])
  end

  def test_returns_false_when_type_is_hash
    refute disallowed_type?({"nested" => "value"}, ["yaml"])
  end

  def test_nil_type_returns_false
    refute disallowed_type?(nil, [nil])
  end

  def test_hash_type_not_checked
    hash_type = {"yaml" => true}

    refute disallowed_type?(hash_type, [hash_type])
  end

  def test_both_conditions_needed
    assert disallowed_type?("yaml", ["yaml"])
    refute disallowed_type?(nil, ["yaml"])
    refute disallowed_type?({"yaml" => true}, ["yaml"])
  end

  def test_with_hash_subclass
    subclass = HashSubclass.new
    subclass["yaml"] = true

    refute disallowed_type?(subclass, [subclass])
  end

  def test_checks_first_condition_type_truthiness
    refute disallowed_type?(false, ["false"])
  end

  def test_with_symbol_in_list
    assert disallowed_type?(:symbol, [:symbol])
  end
end
