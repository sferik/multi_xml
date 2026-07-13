# Backward-compatible alias for the legacy MultiXml constant name
#
# Downstream code that still writes MultiXml.parse(...) or
# rescue MultiXml::ParseError continues to work, but emits a one-time
# deprecation warning pointing at MultiXML. Each public method on
# {MultiXML} gets an explicit forwarder defined on this module, and
# constant access resolves via {.const_missing}, so both dotted calls
# and :: constant lookups (including rescue clauses) route through
# the canonical module.
#
# This file is loaded last by the multi_xml entry point so the
# forwarder snapshot below sees the complete {MultiXML} public API,
# including the deprecated aliases defined in deprecated.rb.
#
# @api public
# @deprecated Use {MultiXML} (all-caps) instead. Will be removed in v1.0.
module MultiXml
  # Forward every public method MultiXML exposes through an explicit
  # singleton method on the legacy MultiXml module, so callers that
  # capture the method as a Method object (``MultiXml.method(:load)``)
  # find this forwarder instead of falling back to inherited methods like
  # ``Kernel#load``. The earlier ``method_missing``-based shim left
  # ``MultiXml.method(:load)`` resolving to ``Kernel#load`` (because
  # ``Module#method`` doesn't consult ``method_missing``) so a captured
  # ``MultiXml.method(:load)`` would interpret the XML payload as a file
  # path and crash with ``LoadError``. Forwarding eagerly fixes the
  # capture path while preserving the one-time deprecation warning each
  # call emits.
  (::MultiXML.public_methods - ::Module.public_methods).each do |forwarded|
    define_singleton_method(forwarded) do |*args, **kwargs, &block|
      ::MultiXML.warn_deprecation_once(:multi_xml_constant,
        "The MultiXml constant is deprecated and will be removed in v1.0. Use MultiXML instead.")
      ::MultiXML.public_send(forwarded, *args, **kwargs, &block)
    end
  end

  class << self
    # Resolve missing constants to their {MultiXML} counterparts
    #
    # The lookup is performed with ``inherit: false`` so a stray
    # top-level ``::ParseError`` constant in the host process (Racc
    # defines one when Nokogiri is loaded) is correctly ignored. Enables
    # rescue MultiXml::ParseError and MultiXml::Parsers::Ox to keep
    # working during the deprecation cycle.
    #
    # @api public
    # @param name [Symbol] constant name
    # @return [Object] the resolved constant from {MultiXML}
    # @example
    #   MultiXml::Parsers::Ox  # returns MultiXML::Parsers::Ox
    def const_missing(name)
      ::MultiXML.warn_deprecation_once(:multi_xml_constant,
        "The MultiXml constant is deprecated and will be removed in v1.0. Use MultiXML instead.")
      ::MultiXML.const_get(name, false)
    end
  end
end
