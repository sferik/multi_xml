require "helper"
require "parser_shared_example"

class MockDecoder
  def self.parse
  end
end

describe "MultiXml" do
  context "with parsers" do
    it "picks a default parser" do
      expect(MultiXml.parser).to be_a(Module).and respond_to(:parse)
    end

    it "defaults to the best available gem" do
      MultiXml.send(:remove_instance_variable, :@parser) if MultiXml.instance_variable_defined?(:@parser)
      expected = jruby? ? "MultiXml::Parsers::Nokogiri" : "MultiXml::Parsers::Ox"
      expect(MultiXml.parser.name).to eq(expected)
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
      expect(MultiXml.parse("<user>Erik</user>", parser: :nokogiri)).to eq({"user" => "Erik"})
    end

    it "allows per-parse parser via string" do
      MultiXml.parser = :rexml
      expect(MultiXml.parse("<user>Erik</user>", parser: "nokogiri")).to eq({"user" => "Erik"})
    end

    it "allows per-parse parser via class" do
      MultiXml.parser = :rexml
      require "multi_xml/parsers/nokogiri"
      expect(MultiXml.parse("<user>Erik</user>", parser: MultiXml::Parsers::Nokogiri)).to eq({"user" => "Erik"})
    end

    it "does not change class-level parser when using per-parse parser" do
      MultiXml.parser = :rexml
      MultiXml.parse("<user>Erik</user>", parser: :nokogiri)
      expect(MultiXml.parser.name).to eq("MultiXml::Parsers::Rexml")
    end

    it "uses class-level parser when :parser option is not provided" do
      MultiXml.parser = :nokogiri
      result = MultiXml.parse("<user>Erik</user>")
      expect(result).to eq({"user" => "Erik"})
    end

    it "raises error for invalid per-parse parser" do
      expect { MultiXml.parse("<user/>", parser: 123) }.to raise_error(RuntimeError, /Invalid parser specification/)
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
    context "with #{parser.first} parser" do
      it_behaves_like "a parser", parser.first
    end
  rescue LoadError
    puts "Tests not run for #{parser.first} due to a LoadError"
  end
end
