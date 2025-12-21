shared_examples_for "a parser" do |parser|
  before do
    MultiXml.parser = parser

    LibXML::XML::Error.set_handler(&LibXML::XML::Error::QUIET_HANDLER) if %w[LibXML libxml_sax].include?(parser)
  rescue LoadError
    pending "Parser #{parser} couldn't be loaded"
  end

  describe ".parse" do
    context "with a blank string" do
      let(:xml) { "" }

      it "returns an empty Hash" do
        expect(MultiXml.parse(xml)).to eq({})
      end
    end

    ["a whitespace string", " ", "a frozen string", " ".freeze].each_slice(2) do |description, xml|
      context description do
        it "returns an empty Hash" do
          expect(MultiXml.parse(xml)).to eq({})
        end
      end
    end

    unless parser == "Oga"
      context "with an invalid XML document" do
        let(:xml) { "<open></close>" }

        it "raises MultiXml::ParseError" do
          expect { MultiXml.parse(xml) }.to raise_error(MultiXml::ParseError)
        end

        it "includes the original XML in the exception" do
          MultiXml.parse(xml)
        rescue MultiXml::ParseError => e
          expect(e.xml).to eq(xml)
        end

        it "includes the underlying cause in the exception" do
          MultiXml.parse(xml)
        rescue MultiXml::ParseError => e
          expect(e.cause).not_to be_nil
        end
      end
    end

    context "with a valid XML document" do
      let(:xml) { "<user/>" }

      it "parses correctly" do
        expect(MultiXml.parse(xml)).to eq("user" => nil)
      end

      context "with CDATA" do
        let(:xml) { "<user><![CDATA[Erik Berlin]]></user>" }

        it "returns the correct CDATA" do
          expect(MultiXml.parse(xml)["user"]).to eq("Erik Berlin")
        end
      end

      context "with whitespace-only content" do
        it "preserves whitespace when no children or attributes" do
          expect(MultiXml.parse("<tag> </tag>")["tag"]).to eq(" ")
        end

        it "preserves multiple spaces when no children or attributes" do
          expect(MultiXml.parse("<tag>   </tag>")["tag"]).to eq("   ")
        end

        it "preserves newlines and tabs when no children or attributes" do
          expect(MultiXml.parse("<tag>\n\t\n</tag>")["tag"]).to eq("\n\t\n")
        end

        it "strips whitespace when there are child elements" do
          expect(MultiXml.parse("<tag> <child/> </tag>")["tag"]).to eq("child" => nil)
        end

        it "strips whitespace when there are attributes" do
          expect(MultiXml.parse('<tag attr="val"> </tag>')["tag"]).to eq("attr" => "val")
        end

        it "preserves content with surrounding whitespace" do
          expect(MultiXml.parse("<tag>  hello  </tag>")["tag"]).to eq("  hello  ")
        end
      end

      context "with element having the same inner element and attribute name" do
        let(:xml) { "<user name='John'><name>Smith</name></user>" }

        it "returns names as Array" do
          expect(MultiXml.parse(xml)["user"]["name"]).to eq %w[John Smith]
        end
      end

      context "with content" do
        let(:xml) { "<user>Erik Berlin</user>" }

        it "returns the correct content" do
          expect(MultiXml.parse(xml)["user"]).to eq("Erik Berlin")
        end
      end

      context "with an attribute" do
        let(:xml) { '<user name="Erik Berlin"/>' }

        it "returns the correct attribute" do
          expect(MultiXml.parse(xml)["user"]["name"]).to eq("Erik Berlin")
        end
      end

      context "with multiple attributes" do
        let(:xml) { '<user name="Erik Berlin" screen_name="sferik"/>' }

        it "returns the correct attributes" do
          expect(MultiXml.parse(xml)["user"]).to include("name" => "Erik Berlin", "screen_name" => "sferik")
        end
      end

      context "with typecast_xml_value: true (default)" do
        it "typecasts string type" do
          xml = "<global-settings><group><name>Settings</name>" \
                '<setting type="string"><description>Test</description></setting></group></global-settings>'
          setting = MultiXml.parse(xml)["global_settings"]["group"]["setting"]
          expect(setting).to eq ""
        end
      end

      context "with typecast_xml_value: false" do
        it "preserves type attribute" do
          xml = "<global-settings><group><name>Settings</name>" \
                '<setting type="string"><description>Test</description></setting></group></global-settings>'
          setting = MultiXml.parse(xml, typecast_xml_value: false)["global_settings"]["group"]["setting"]
          expect(setting).to eq("type" => "string", "description" => {"__content__" => "Test"})
        end
      end

      context "with :symbolize_keys => true" do
        let(:xml) { '<users><user name="Erik Berlin"/><user><name>Wynn Netherland</name></user></users>' }

        it "symbolizes keys" do
          expect(MultiXml.parse(xml,
            symbolize_keys: true)).to eq(users: {user: [{name: "Erik Berlin"},
              {name: "Wynn Netherland"}]})
        end
      end

      context 'with an attribute type="boolean"' do
        it "returns true for 'true'" do
          expect(MultiXml.parse('<tag type="boolean">true</tag>')["tag"]).to be true
        end

        it "returns false for 'false'" do
          expect(MultiXml.parse('<tag type="boolean">false</tag>')["tag"]).to be false
        end

        it "returns true for '1'" do
          expect(MultiXml.parse('<tag type="boolean">1</tag>')["tag"]).to be true
        end

        it "returns false for '0'" do
          expect(MultiXml.parse('<tag type="boolean">0</tag>')["tag"]).to be false
        end
      end

      context 'with an attribute type="integer"' do
        it "returns a positive Integer" do
          result = MultiXml.parse('<tag type="integer">1</tag>')["tag"]
          expect(result).to be_a(Integer).and eq(1)
        end

        it "returns a negative Integer" do
          result = MultiXml.parse('<tag type="integer">-1</tag>')["tag"]
          expect(result).to be_a(Integer).and eq(-1)
        end
      end

      context 'with an attribute type="string"' do
        let(:xml) { '<tag type="string"></tag>' }

        it "returns a String" do
          expect(MultiXml.parse(xml)["tag"]).to be_a(String)
        end

        it "returns the correct string" do
          expect(MultiXml.parse(xml)["tag"]).to eq("")
        end
      end

      context 'with an attribute type="date"' do
        let(:xml) { '<tag type="date">1970-01-01</tag>' }

        it "returns a Date" do
          expect(MultiXml.parse(xml)["tag"]).to be_a(Date)
        end

        it "returns the correct date" do
          expect(MultiXml.parse(xml)["tag"]).to eq(Date.parse("1970-01-01"))
        end
      end

      %w[datetime dateTime].each do |type|
        context %(with an attribute type="#{type}") do
          let(:xml) { %(<tag type="#{type}">1970-01-01 00:00</tag>) }

          it "returns a Time" do
            expect(MultiXml.parse(xml)["tag"]).to be_a(Time)
          end

          it "returns the correct time" do
            expect(MultiXml.parse(xml)["tag"]).to eq(Time.parse("1970-01-01 00:00"))
          end
        end
      end

      context 'with an attribute type="double"' do
        let(:xml) { '<tag type="double">3.14159265358979</tag>' }

        it "returns a Float" do
          expect(MultiXml.parse(xml)["tag"]).to be_a(Float)
        end

        it "returns the correct number" do
          expect(MultiXml.parse(xml)["tag"]).to eq(3.14159265358979)
        end
      end

      context 'with an attribute type="decimal"' do
        let(:xml) { '<tag type="decimal">3.14159265358979</tag>' }

        it "returns a BigDecimal" do
          expect(MultiXml.parse(xml)["tag"]).to be_a(BigDecimal)
        end

        it "returns the correct number" do
          expect(MultiXml.parse(xml)["tag"]).to eq(3.14159265358979)
        end
      end

      context 'with an attribute type="base64Binary"' do
        let(:xml) { '<tag type="base64Binary">aW1hZ2UucG5n</tag>' }

        it "returns a String" do
          expect(MultiXml.parse(xml)["tag"]).to be_a(String)
        end

        it "returns the correct string" do
          expect(MultiXml.parse(xml)["tag"]).to eq("image.png")
        end
      end

      context 'with an attribute type="yaml"' do
        let(:xml) do
          "<tag type=\"yaml\">--- \n1: returns an integer\n:message: Have a nice day\n" \
            "array: \n- has-dashes: true\n  has_underscores: true\n</tag>"
        end

        it "raises MultiXML::DisallowedTypeError by default" do
          expect { MultiXml.parse(xml)["tag"] }.to raise_error(MultiXml::DisallowedTypeError)
        end

        it "returns the correctly parsed YAML when the type is allowed" do
          expect(MultiXml.parse(xml,
            disallowed_types: [])["tag"]).to eq(:message => "Have a nice day", 1 => "returns an integer",
              "array" => [{"has-dashes" => true, "has_underscores" => true}])
        end
      end

      context 'with an attribute type="symbol"' do
        let(:xml) { '<tag type="symbol">my_symbol</tag>' }

        it "raises MultiXML::DisallowedTypeError" do
          expect { MultiXml.parse(xml)["tag"] }.to raise_error(MultiXml::DisallowedTypeError)
        end

        it "returns the correctly parsed Symbol when the type is allowed" do
          expect(MultiXml.parse(xml, disallowed_types: [])["tag"]).to eq(:my_symbol)
        end
      end

      context 'with an attribute type="file"' do
        let(:xml) { '<tag type="file" name="data.txt" content_type="text/plain">ZGF0YQ==</tag>' }

        it "returns a StringIO" do
          expect(MultiXml.parse(xml)["tag"]).to be_a(StringIO)
        end

        it "is decoded correctly" do
          expect(MultiXml.parse(xml)["tag"].string).to eq("data")
        end

        it "has the correct file name" do
          expect(MultiXml.parse(xml)["tag"].original_filename).to eq("data.txt")
        end

        it "has the correct content type" do
          expect(MultiXml.parse(xml)["tag"].content_type).to eq("text/plain")
        end
      end

      context 'with an attribute type="file" with missing name and content type' do
        let(:xml) { '<tag type="file">ZGF0YQ==</tag>' }

        it "returns a StringIO" do
          expect(MultiXml.parse(xml)["tag"]).to be_a(StringIO)
        end

        it "is decoded correctly" do
          expect(MultiXml.parse(xml)["tag"].string).to eq("data")
        end

        it "has the default file name" do
          expect(MultiXml.parse(xml)["tag"].original_filename).to eq("untitled")
        end

        it "has the default content type" do
          expect(MultiXml.parse(xml)["tag"].content_type).to eq("application/octet-stream")
        end
      end

      context 'with an attribute type="array"' do
        let(:xml) { '<users type="array"><user>Erik Berlin</user><user>Wynn Netherland</user></users>' }

        it "returns an Array" do
          expect(MultiXml.parse(xml)["users"]).to be_a(Array)
        end

        it "returns the correct array" do
          expect(MultiXml.parse(xml)["users"]).to eq(["Erik Berlin", "Wynn Netherland"])
        end
      end

      context 'with an attribute type="array" in addition to other attributes' do
        let(:xml) { '<users type="array" foo="bar"><user>Erik Berlin</user><user>Wynn Netherland</user></users>' }

        it "returns an Array" do
          expect(MultiXml.parse(xml)["users"]).to be_a(Array)
        end

        it "returns the correct array" do
          expect(MultiXml.parse(xml)["users"]).to eq(["Erik Berlin", "Wynn Netherland"])
        end
      end

      context 'with an attribute type="array" containing only one item' do
        let(:xml) { '<users type="array"><user>Erik Berlin</user></users>' }

        it "returns an Array" do
          expect(MultiXml.parse(xml)["users"]).to be_a(Array)
        end

        it "returns the correct array" do
          expect(MultiXml.parse(xml)["users"]).to eq(["Erik Berlin"])
        end
      end

      %w[integer boolean date datetime file].each do |type|
        context "with an empty attribute type=\"#{type}\"" do
          let(:xml) { "<tag type=\"#{type}\"/>" }

          it "returns nil" do
            expect(MultiXml.parse(xml)["tag"]).to be_nil
          end
        end
      end

      %w[yaml symbol].each do |type|
        context "with an empty attribute type=\"#{type}\"" do
          let(:xml) { "<tag type=\"#{type}\"/>" }

          it "raises MultiXml::DisallowedTypeError by default" do
            expect { MultiXml.parse(xml)["tag"] }.to raise_error(MultiXml::DisallowedTypeError)
          end

          it "returns nil when the type is allowed" do
            expect(MultiXml.parse(xml, disallowed_types: [])["tag"]).to be_nil
          end
        end
      end

      context 'with an empty attribute type="array"' do
        it "returns an empty Array" do
          expect(MultiXml.parse('<tag type="array"/>')["tag"]).to eq([])
        end

        it "returns an empty Array with whitespace" do
          expect(MultiXml.parse('<tag type="array"> </tag>')["tag"]).to eq([])
        end
      end

      context "with XML entities in content" do
        it "returns unescaped XML entities" do
          {"<" => "&lt;", ">" => "&gt;", '"' => "&quot;", "'" => "&apos;", "&" => "&amp;"}.each do |char, entity|
            expect(MultiXml.parse("<tag>#{entity}</tag>")["tag"]).to eq(char)
          end
        end
      end

      context "with XML entities in attribute" do
        it "returns unescaped XML entities" do
          {"<" => "&lt;", ">" => "&gt;", '"' => "&quot;", "'" => "&apos;", "&" => "&amp;"}.each do |char, entity|
            expect(MultiXml.parse("<tag attribute=\"#{entity}\"/>")["tag"]["attribute"]).to eq(char)
          end
        end
      end

      context "with dasherized tag" do
        let(:xml) { "<tag-1/>" }

        it "returns undasherize tag" do
          expect(MultiXml.parse(xml).keys).to include("tag_1")
        end
      end

      context "with dasherized attribute" do
        let(:xml) { '<tag attribute-1="1"></tag>' }

        it "returns undasherize attribute" do
          expect(MultiXml.parse(xml)["tag"].keys).to include("attribute_1")
        end
      end

      context "with children with attributes" do
        it "returns the correct attributes" do
          xml = '<users><user name="Erik Berlin"/></users>'
          expect(MultiXml.parse(xml)["users"]["user"]["name"]).to eq("Erik Berlin")
        end
      end

      context "with children with text" do
        it "returns the correct text" do
          xml = "<user><name>Erik Berlin</name></user>"
          expect(MultiXml.parse(xml)["user"]["name"]).to eq("Erik Berlin")
        end
      end

      context "with children with an unrecognized attribute type" do
        it "passes through the type" do
          xml = '<user type="admin"><name>Erik Berlin</name></user>'
          expect(MultiXml.parse(xml)["user"]["type"]).to eq("admin")
        end
      end

      context "with children with non 'type' attribute tags on content nodes" do
        it "adds the attributes to the value hash", :aggregate_failures do
          xml = "<options><value currency='USD'>123</value><value number='percent'>0.123</value></options>"
          values = MultiXml.parse(xml)["options"]["value"]
          expect(values[0]).to include("__content__" => "123", "currency" => "USD")
          expect(values[1]).to include("__content__" => "0.123", "number" => "percent")
        end
      end

      context "with children with unrecognized type attribute tags on content nodes" do
        it "adds the attributes to the value hash passing through the type", :aggregate_failures do
          xml = "<options><value type='USD'>123</value><value type='percent'>0.123</value><value currency='USD'>123</value></options>"
          values = MultiXml.parse(xml)["options"]["value"]
          expect(values[0]).to include("__content__" => "123", "type" => "USD")
          expect(values[1]).to include("__content__" => "0.123", "type" => "percent")
          expect(values[2]).to include("__content__" => "123", "currency" => "USD")
        end
      end

      context "with children mixing attributes and non-attributes content nodes" do
        it "adds the attributes to the value hash passing through the type", :aggregate_failures do
          xml = "<options><value type='USD'>123</value><value type='percent'>0.123</value><value>123</value></options>"
          values = MultiXml.parse(xml)["options"]["value"]
          expect(values[0]).to include("__content__" => "123", "type" => "USD")
          expect(values[1]).to include("__content__" => "0.123", "type" => "percent")
          expect(values[2]).to eq("123")
        end
      end

      context "with children mixing recognized type attribute and non-type attributes" do
        it "adds the non-type attribute and typecasts" do
          xml = "<options><value number='USD' type='integer'>123</value></options>"
          expect(MultiXml.parse(xml)["options"]["value"]).to include("__content__" => 123, "number" => "USD")
        end
      end

      context "with children mixing unrecognized type attribute and non-type attributes" do
        it "adds all attributes to the value hash" do
          xml = "<options><value number='USD' type='currency'>123</value></options>"
          expect(MultiXml.parse(xml)["options"]["value"]).to include("__content__" => "123", "number" => "USD", "type" => "currency")
        end
      end

      context "with children with newlines and whitespace" do
        it "parses correctly" do
          xml = "<user>\n  <name>Erik Berlin</name>\n</user>"
          expect(MultiXml.parse(xml)).to eq("user" => {"name" => "Erik Berlin"})
        end
      end

      context "with nested children" do
        it "parses correctly" do
          xml = '<users><user name="Erik Berlin"><status text="Hello"/></user></users>'
          expect(MultiXml.parse(xml)).to eq("users" => {"user" => {"name" => "Erik Berlin", "status" => {"text" => "Hello"}}})
        end
      end

      context "with sibling children" do
        let(:xml) { "<users><user>Erik Berlin</user><user>Wynn Netherland</user></users>" }

        it "returns an Array" do
          expect(MultiXml.parse(xml)["users"]["user"]).to be_a(Array)
        end

        it "parses correctly" do
          expect(MultiXml.parse(xml)).to eq("users" => {"user" => ["Erik Berlin", "Wynn Netherland"]})
        end
      end
    end

    context "with a duplexed stream" do
      let(:xml) do
        rd, wr = IO.pipe
        Thread.new do
          "<user/>".each_char do |chunk|
            wr << chunk
          end
          wr.close
        end
        rd
      end

      it "parses correctly" do
        expect(MultiXml.parse(xml)).to eq("user" => nil)
      end
    end
  end
end
