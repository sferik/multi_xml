
# Shared setup that configures the parser backend before each test
module ParserTestSetup
  def self.included(base)
    base.extend(Mutant::Minitest::Coverage)
    base.cover("MultiXml*")
  end

  def setup
    MultiXml.parser = self.class::PARSER
    LibXML::XML::Error.set_handler(&LibXML::XML::Error::QUIET_HANDLER) if %w[LibXML libxml_sax].include?(self.class::PARSER)
  rescue LoadError
    skip "Parser #{self.class::PARSER} couldn't be loaded"
  end
end
