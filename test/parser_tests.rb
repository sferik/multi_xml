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

module ParserTests
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
