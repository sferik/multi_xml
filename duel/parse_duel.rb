# MultiXML.parse with the default parser (Ox, pinned in duel_helper.rb)
# and default options: typecasting on, and namespaces stripped. Each
# document is built and parsed once, untimed, so the parser is detected
# and loaded before anything is measured.
require_relative "duel_helper"

duel "parse: a tiny document" do
  once { MultiXML.parse(@xml = tiny_document) }
  MultiXML.parse(@xml)
end

duel "parse: 10 records" do
  once { MultiXML.parse(@xml = record_document(10)) }
  MultiXML.parse(@xml)
end

duel "parse: 120 records" do
  once { MultiXML.parse(@xml = record_document(120)) }
  MultiXML.parse(@xml)
end

duel "parse: a large catalog" do
  once { MultiXML.parse(@xml = catalog_document(100)) }
  MultiXML.parse(@xml)
end

duel "parse: 450 shallow fields" do
  once { MultiXML.parse(@xml = shallow_document(450)) }
  MultiXML.parse(@xml)
end

duel "parse: a tree 180 levels deep" do
  once { MultiXML.parse(@xml = deep_document(180)) }
  MultiXML.parse(@xml)
end

duel "parse: attribute-dense nodes" do
  once { MultiXML.parse(@xml = attribute_document(100)) }
  MultiXML.parse(@xml)
end

duel "parse: mixed content" do
  once { MultiXML.parse(@xml = mixed_document(60)) }
  MultiXML.parse(@xml)
end

duel "parse: a feed, namespaces stripped" do
  once { MultiXML.parse(@xml = feed_document(60)) }
  MultiXML.parse(@xml)
end

duel "parse: a feed, namespaces preserved" do
  once { MultiXML.parse(@xml = feed_document(60), namespaces: :preserve) }
  MultiXML.parse(@xml, namespaces: :preserve)
end

duel "parse: dashed keys" do
  once { MultiXML.parse(@xml = dashed_document(100)) }
  MultiXML.parse(@xml)
end

duel "parse: 120 records, symbolized names" do
  once { MultiXML.parse(@xml = record_document(120), symbolize_names: true) }
  MultiXML.parse(@xml, symbolize_names: true)
end

duel "parse: 120 records, no typecasting" do
  once { MultiXML.parse(@xml = record_document(120), typecast_xml_value: false) }
  MultiXML.parse(@xml, typecast_xml_value: false)
end

duel "parse: 10 records from an IO" do
  once { MultiXML.parse(@io = StringIO.new(record_document(10))) }
  @io.rewind
  MultiXML.parse(@io)
end
