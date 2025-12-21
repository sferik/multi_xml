require "helper"
require "parser_shared_example"

class MockDecoder
  def self.parse
  end
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

    it "allows per-parse parser via symbol" do
      MultiXml.parser = :rexml
      result = MultiXml.parse("<user>Erik</user>", parser: :nokogiri)
      expect(result).to eq({"user" => "Erik"})
      # Class-level parser should remain unchanged
      expect(MultiXml.parser.name).to eq("MultiXml::Parsers::Rexml")
    end

    it "allows per-parse parser via string" do
      MultiXml.parser = :rexml
      result = MultiXml.parse("<user>Erik</user>", parser: "nokogiri")
      expect(result).to eq({"user" => "Erik"})
      expect(MultiXml.parser.name).to eq("MultiXml::Parsers::Rexml")
    end

    it "allows per-parse parser via class" do
      MultiXml.parser = :rexml
      require "multi_xml/parsers/nokogiri"
      result = MultiXml.parse("<user>Erik</user>", parser: MultiXml::Parsers::Nokogiri)
      expect(result).to eq({"user" => "Erik"})
      expect(MultiXml.parser.name).to eq("MultiXml::Parsers::Rexml")
    end

    it "uses class-level parser when :parser option is not provided" do
      MultiXml.parser = :nokogiri
      result = MultiXml.parse("<user>Erik</user>")
      expect(result).to eq({"user" => "Erik"})
    end

    it "raises error for invalid per-parse parser" do
      expect { MultiXml.parse("<user/>", parser: 123) }.to raise_error(RuntimeError, /Did not recognize your parser specification/)
    end

    it "wraps parser errors correctly with per-parse parser" do
      expect { MultiXml.parse("<open></close>", parser: :nokogiri) }.to raise_error(MultiXml::ParseError)
    end
  end

  [%w[LibXML libxml],
    %w[libxml_sax libxml],
    %w[REXML rexml/document],
    %w[Nokogiri nokogiri],
    %w[nokogiri_sax nokogiri],
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
