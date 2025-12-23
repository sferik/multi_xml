D = Steep::Diagnostic

target :lib do
  signature "sig"

  # Check core library files (excluding parser implementations that depend on optional gems)
  check "lib/multi_xml.rb"
  check "lib/multi_xml/constants.rb"
  check "lib/multi_xml/errors.rb"
  check "lib/multi_xml/file_like.rb"
  check "lib/multi_xml/helpers.rb"
  check "lib/multi_xml/version.rb"

  # Use stdlib types
  library "date"
  library "time"
  library "yaml"
  library "bigdecimal"
  library "stringio"

  configure_code_diagnostics(D::Ruby.strict)
end
