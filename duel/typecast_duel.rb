# Typecasting values by their type attributes (integer, float, decimal,
# boolean, date, dateTime, nil, and array), as Rails' to_xml writes them.
require_relative "duel_helper"

duel "typecast: one typed record" do
  once { MultiXML.parse(@xml = typed_document(1)) }
  MultiXML.parse(@xml)
end

duel "typecast: 50 typed records" do
  once { MultiXML.parse(@xml = typed_document(50)) }
  MultiXML.parse(@xml)
end
