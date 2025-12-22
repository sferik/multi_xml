require "parser_tests/parser_test_setup"
require "parser_tests/parser_basic_tests"
require "parser_tests/parser_whitespace_tests"
require "parser_tests/parser_attribute_tests"
require "parser_tests/parser_typecast_tests"
require "parser_tests/parser_yaml_symbol_tests"
require "parser_tests/parser_file_array_tests"
require "parser_tests/parser_empty_type_tests"
require "parser_tests/parser_entity_tests"
require "parser_tests/parser_children_tests"
require "parser_tests/parser_mixed_attribute_tests"
require "parser_tests/parser_stream_tests"

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
