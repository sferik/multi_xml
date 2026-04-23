module DeprecationHelpers
  def reset_deprecation_registry
    @shown = MultiXML.send(:const_get, :DEPRECATION_WARNINGS_SHOWN)
    @original_shown = @shown.dup
    @shown.clear
  end

  def restore_deprecation_registry
    @shown.replace(@original_shown)
  end

  def stub_kernel_warn
    @original_warn = Kernel.method(:warn)
    @warnings = []
    @warn_opts = []
    warnings = @warnings
    warn_opts = @warn_opts
    stub_warn do |msg, **opts|
      warnings << msg
      warn_opts << opts
    end
  end

  def stub_warn(&)
    old_verbose = $VERBOSE
    $VERBOSE = nil
    Kernel.define_singleton_method(:warn, &)
  ensure
    $VERBOSE = old_verbose
  end

  def restore_warn
    old_verbose = $VERBOSE
    $VERBOSE = nil
    Kernel.define_singleton_method(:warn, @original_warn)
  ensure
    $VERBOSE = old_verbose
  end
end
