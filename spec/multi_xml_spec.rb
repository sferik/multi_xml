require "helper"
require "parser_shared_example"

class MockDecoder
  def self.parse; end
end

describe "MultiXml" do
  context "Parsers" do
    it "picks a default parser" do
      expect(MultiXml.parser).to be_a(Module)
      expect(MultiXml.parser).to respond_to(:parse)
    end

    it "defaults to the best available gem" do
      # Clear cache variable possibly set by previous tests
      MultiXml.send(:remove_instance_variable, :@parser) if MultiXml.instance_variable_defined?(:@parser)
      if jruby?
        # Ox and Libxml are not not currently available on JRuby, so Nokogiri is the best available gem
        expect(MultiXml.parser.name).to eq("MultiXml::Parsers::Nokogiri")
      else
        expect(MultiXml.parser.name).to eq("MultiXml::Parsers::Ox")
      end
    end

    it "is settable via a symbol" do
      MultiXml.parser = :rexml
      expect(MultiXml.parser.name).to eq("MultiXml::Parsers::Rexml")
    end

    it "is settable via a class" do
      MultiXml.parser = MockDecoder
      expect(MultiXml.parser.name).to eq("MockDecoder")
    end
  end

  [%w[LibXML libxml],
   %w[REXML rexml/document],
   %w[Nokogiri nokogiri],
   %w[Ox ox],
   %w[Oga oga]].each do |parser|
    require parser.last
    context "#{parser.first} parser" do
      it_behaves_like "a parser", parser.first
    end
  rescue LoadError
    puts "Tests not run for #{parser.first} due to a LoadError"
  end
end
