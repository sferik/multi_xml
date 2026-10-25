# The same 20 records through each of the other backends, picked per
# call with the :parser option. The backend's module is resolved once,
# untimed, so each iteration times only the parse and the hash-building
# that MultiXML's own handler for that backend does.
require_relative "duel_helper"

{
  "libxml" => :libxml,
  "libxml SAX" => :libxml_sax,
  "nokogiri" => :nokogiri,
  "nokogiri SAX" => :nokogiri_sax,
  "oga" => :oga,
  "rexml" => :rexml
}.each do |label, name|
  duel "backend: #{label}, 20 records" do
    once do
      @parser = MultiXML.with_parser(name) { MultiXML.parser }
      MultiXML.parse(@xml = record_document(20), parser: @parser)
    end
    MultiXML.parse(@xml, parser: @parser)
  end
end
