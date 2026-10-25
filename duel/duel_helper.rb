# Shared XML documents for the benchmarks. Every document is built from
# fixed inputs, so each iteration and each version parses the same bytes.
# The shapes follow the payloads in benchmark.rb.

# Auto-detection picks the first parser library already loaded, so which
# one a worker gets would depend on whether a backend benchmark loaded
# LibXML or Nokogiri before the first parse. Pin Ox, the one detection
# prefers, so every worker of both versions parses with the same backend.
MultiXML.parser = :ox

def token(prefix, index, width)
  base = "#{prefix}_#{index.to_s(36)}_abcdefghijklmnopqrstuvwxyz0123456789"
  (base * (width.to_f / base.length).ceil)[0, width]
end

def timestamp(index)
  Kernel.format("2026-04-%<day>02dT12:%<minute>02d:56Z", day: (index % 28) + 1, minute: index % 60)
end

def wrap_root(inner) = "<root>#{inner}</root>"

def tiny_document = "<user><name>Erik</name><active>yes</active></user>"

def shallow_document(count)
  wrap_root(Array.new(count) { |i| "<field#{i}>#{token("node", i, 24)}</field#{i}>" }.join)
end

def deep_document(depth)
  open_tags = Array.new(depth) { |i| %(<level#{i} depth="#{i}"><value>#{token("value", i, 24)}</value>) }
  wrap_root(open_tags.join + Array.new(depth) { |i| "</level#{depth - 1 - i}>" }.join)
end

def record(index)
  status = (index % 3).zero? ? "active" : "pending"
  amount = Kernel.format("%.2f", ((index * 17) % 10_000) / 10.0)
  %(<record id="#{index}"><title>#{token("title", index, 40)}</title><status>#{status}</status>) +
    "<created_at>#{timestamp(index)}</created_at><amount>#{amount}</amount>" \
    "<tags><tag>alpha</tag><tag>beta</tag><tag>#{token("tag", index, 12)}</tag></tags></record>"
end

def record_document(count) = wrap_root(Array.new(count) { |i| record(i) }.join)

def attribute_document(count)
  nodes = Array.new(count) do |i|
    attrs = Array.new(8) { |slot| %(a#{slot}="#{token("attr", i + slot, 14)}") }.join(" ")
    "<node #{attrs}>#{token("node", i, 18)}</node>"
  end
  wrap_root(nodes.join)
end

def mixed_document(count)
  sections = Array.new(count) do |i|
    %(<section id="s#{i}"><title>#{token("title", i, 28)}</title>) +
      "<p>This #{token("text", i, 18)} text has <em>inline emphasis #{i}</em> and <strong>strong #{i}</strong>.</p>" \
      "<p>#{token("body", i + 1, 46)} <a href=\"https://example.test/#{i}\">link #{i}</a> #{token("tail", i + 2, 20)}</p></section>"
  end
  wrap_root(sections.join)
end

def feed_document(count)
  entries = Array.new(count) do |i|
    %(<atom:entry gd:id="item-#{i}" ex:version="#{i}"><atom:title>#{token("title", i, 34)}</atom:title>) +
      %(<atom:content type="text">#{token("content", i, 58)}</atom:content><gd:rating value="#{(i % 5) + 1}"/>) +
      %(<ex:metadata ex:region="us-west-2" ex:trace="trace-#{i}"/></atom:entry>)
  end
  namespaces = %(xmlns:atom="http://www.w3.org/2005/Atom" xmlns:gd="http://schemas.google.com/g/2005" xmlns:ex="https://example.test/schema")
  %(<atom:feed #{namespaces}>#{entries.join}</atom:feed>)
end

def product(index)
  [
    %(<product sku="sku-#{index}" region="us" updated="#{timestamp(index)}"><name>#{token("name", index, 30)}</name>),
    %(<price currency="USD">#{Kernel.format("%.2f", ((index * 13) % 100_000) / 100.0)}</price>),
    %(<inventory available="#{index % 2}" warehouse="w#{index % 11}">#{(index * 7) % 400}</inventory>),
    "<categories><category>hardware</category><category>component</category>",
    "<category>#{token("category", index, 12)}</category></categories>",
    product_dimensions(index),
    "<description>#{token("description", index, 120)}</description></product>"
  ].join
end

def product_dimensions(index)
  "<dimensions><width>#{(index % 100) + 1}</width><height>#{(index % 80) + 1}</height><depth>#{(index % 50) + 1}</depth></dimensions>"
end

def catalog_document(count) = wrap_root(Array.new(count) { |i| product(i) }.join)

# Records whose values carry type attributes, as Rails' to_xml writes
# them, so that typecasting converts every one.
def typed_record(index)
  [
    %(<user><id type="integer">#{index}</id><name>#{token("name", index, 20)}</name>),
    %(<score type="float">#{index}.5</score><balance type="decimal">#{index}.25</balance>),
    %(<admin type="boolean">#{index.even?}</admin><born-on type="date">2001-02-#{(index % 28) + 1}</born-on>),
    %(<updated-at type="dateTime">#{timestamp(index)}</updated-at><nickname nil="true"/>),
    %(<roles type="array"><role>reader</role><role>writer</role></roles></user>)
  ].join
end

def typed_document(count) = %(<users type="array">#{Array.new(count) { |i| typed_record(i) }.join}</users>)

def dashed_document(count)
  wrap_root(Array.new(count) { |i| "<first-name-#{i}>#{token("first", i, 16)}</first-name-#{i}>" }.join)
end
