require "test_setup"
require "basic_tests"
require "whitespace_tests"
require "attribute_tests"
require "typecast_tests"
require "yaml_symbol_tests"
require "file_array_tests"
require "empty_type_tests"
require "entity_tests"
require "children_tests"
require "mixed_attribute_tests"
require "stream_tests"

# Common tests that run on all parsers
module ParserCommonTests
  include ParserTestSetup
  include ParserBasicTests
  include ParserWhitespaceTests
  include ParserAttributeTests
  include ParserTypecastTests
  include ParserYamlSymbolTests
  include ParserFileArrayTests
  include ParserEmptyTypeTests
  include ParserEntityTests
  include ParserChildrenTests
  include ParserMixedAttributeTests
  include ParserStreamTests
end

# Tests for DOM parsers (all parsers except SAX variants)
module DomParserTests
  include ParserCommonTests
  include ParserStrictErrorTests
end

# Tests for DOM parsers that don't raise on invalid XML (Oga)
module LenientDomParserTests
  include ParserCommonTests
end

# Tests for SAX parsers
module SaxParserFullTests
  include ParserCommonTests
  include ParserStrictErrorTests
  include SaxParserTests
end
