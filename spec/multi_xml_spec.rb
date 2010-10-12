require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class MockDecoder
  def self.parse(string)
    '<tag>This is the contents</tag>'
  end
end

describe "MultiXml" do
  context "Parsers" do
    it "should default to the best available gem" do
      require 'libxml'
      MultiXml.parser.name.should == 'MultiXml::Parsers::Libxml'
    end

    it "should be settable via a symbol" do
      MultiXml.parser = :libxml
      MultiXml.parser.name.should == 'MultiXml::Parsers::Libxml'
    end

    it "should be settable via a class" do
      MultiXml.parser = MockDecoder
      MultiXml.parser.name.should == 'MockDecoder'
    end
  end

  Dir.glob('lib/multi_xml/parsers/**/*.rb').map{|file| File.basename(file, ".rb").split('_').map{|s| s.capitalize}.join('')}.each do |parser|
    context "Parsers::#{parser}" do
      before do
        begin
          MultiXml.parser = parser
        rescue LoadError
          pending "Parser #{parser} couldn't be loaded"
        end
      end

      describe ".parse" do
        context "a blank string" do
          before do
            @string = ''
          end

          it "should return an empty Hash" do
            MultiXml.parse(@string).should == {}
          end
        end

        context "a whitespace string" do
          before do
            @string = ' '
          end

          it "should return an empty Hash" do
            MultiXml.parse(@string).should == {}
          end
        end

        context "a single-node document" do

          before do
            @string = '<user/>'
          end

          it "should parse correctly" do
            MultiXml.parse(@string).should == {'user' => nil}
          end

          context "with CDATA" do
            before do
              @string = '<user><![CDATA[Erik Michaels-Ober]]></user>'
            end

            it "should parse correctly" do
              MultiXml.parse(@string).should == {"user" => "Erik Michaels-Ober"}
            end
          end

          context "with content" do
            before do
              @string = '<user>Erik Michaels-Ober</user>'
            end

            it "should parse correctly" do
              MultiXml.parse(@string).should == {"user" => "Erik Michaels-Ober"}
            end
          end

          context "with an attribute" do
            before do
              @string = '<user name="Erik Michaels-Ober"/>'
            end

            it "should parse correctly" do
              MultiXml.parse(@string).should == {"user" => {"name" => "Erik Michaels-Ober"}}
            end
          end

          context "with multiple attributes" do
            before do
              @string = '<user name="Erik Michaels-Ober" screen_name="sferik"/>'
            end

            it "should parse correctly" do
              MultiXml.parse(@string).should == {"user" => {"name" => "Erik Michaels-Ober", "screen_name" => "sferik"}}
            end
          end

          context "with :symbolize_keys => true" do
            before do
              @string = '<user name="Erik Michaels-Ober"/>'
            end

            it "should symbolize keys" do
              MultiXml.parse(@string, :symbolize_keys => true).should == {:user => {:name => "Erik Michaels-Ober"}}
            end
          end

          context "with an attribute type=\"boolean\"" do
            %w(true false).each do |boolean|
              context "when #{boolean}" do
                it "should be #{boolean}" do
                  string = "<tag type=\"boolean\">#{boolean}</tag>"
                  MultiXml.parse(string)['tag'].should instance_eval("be_#{boolean}")
                end
              end
            end

            context "when 1" do
              before do
                @string = '<tag type="boolean">1</tag>'
              end

              it "should be true" do
                MultiXml.parse(@string)['tag'].should be_true
              end
            end

            context "when 0" do
              before do
                @string = '<tag type="boolean">0</tag>'
              end

              it "should be false" do
                MultiXml.parse(@string)['tag'].should be_false
              end
            end
          end

          context "with an attribute type=\"integer\"" do
            context "with a positive integer" do
              before do
                @string = '<tag type="integer">1</tag>'
              end

              it "should be a Fixnum" do
                MultiXml.parse(@string)['tag'].should be_a(Fixnum)
              end

              it "should be the correct number" do
                MultiXml.parse(@string)['tag'].should == 1
              end
            end

            context "with a negative integer" do
              before do
                @string = '<tag type="integer">-1</tag>'
              end

              it "should be a Fixnum" do
                MultiXml.parse(@string)['tag'].should be_a(Fixnum)
              end

              it "should be the correct number" do
                MultiXml.parse(@string)['tag'].should == -1
              end
            end
          end

          context "with an attribute type=\"string\"" do
            before do
              @string = '<tag type="string"></tag>'
            end

            it "should be a String" do
              MultiXml.parse(@string)['tag'].should be_a(String)
            end

            it "should be the correct string" do
              MultiXml.parse(@string)['tag'].should == ""
            end
          end

          context "with an attribute type=\"date\"" do
            before do
              @string = '<tag type="date">1970-01-01</tag>'
            end

            it "should be a Date" do
              MultiXml.parse(@string)['tag'].should be_a(Date)
            end

            it "should be the correct date" do
              MultiXml.parse(@string)['tag'].should == Date.parse('1970-01-01')
            end
          end

          context "with an attribute type=\"datetime\"" do
            before do
              @string = '<tag type="datetime">1970-01-01 00:00</tag>'
            end

            it "should be a Time" do
              MultiXml.parse(@string)['tag'].should be_a(Time)
            end

            it "should be the correct time" do
              MultiXml.parse(@string)['tag'].should == Time.parse('1970-01-01 00:00')
            end
          end

          context "with an attribute type=\"dateTime\"" do
            before do
              @string = '<tag type="datetime">1970-01-01 00:00</tag>'
            end

            it "should be a Time" do
              MultiXml.parse(@string)['tag'].should be_a(Time)
            end

            it "should be the correct time" do
              MultiXml.parse(@string)['tag'].should == Time.parse('1970-01-01 00:00')
            end
          end

          context "with an attribute type=\"double\"" do
            before do
              @string = '<tag type="double">3.14159265358979</tag>'
            end

            it "should be a Float" do
              MultiXml.parse(@string)['tag'].should be_a(Float)
            end

            it "should be the correct number" do
              MultiXml.parse(@string)['tag'].should == 3.14159265358979
            end
          end

          context "with an attribute type=\"decimal\"" do
            before do
              @string = '<tag type="decimal">3.14159265358979323846264338327950288419716939937510</tag>'
            end

            it "should be a BigDecimal" do
              MultiXml.parse(@string)['tag'].should be_a(BigDecimal)
            end

            it "should be the correct number" do
              MultiXml.parse(@string)['tag'].should == 3.14159265358979323846264338327950288419716939937510
            end
          end

          context "with an attribute type=\"base64Binary\"" do
            before do
              @string = '<tag type="base64Binary">aW1hZ2UucG5n</tag>'
            end

            it "should be a String" do
              MultiXml.parse(@string)['tag'].should be_a(String)
            end

            it "should be the correct string" do
              MultiXml.parse(@string)['tag'].should == "image.png"
            end
          end

          context "with an attribute type=\"yaml\"" do
            before do
              @string = "<tag type=\"yaml\">--- \n1: should be an integer\n:message: Have a nice day\narray: \n- should-have-dashes: true\n  should_have_underscores: true\n</tag>"
            end

            it "should parse correctly" do
              MultiXml.parse(@string)['tag'].should == {:message => "Have a nice day", 1 => "should be an integer", "array" => [{"should-have-dashes" => true, "should_have_underscores" => true}]}
            end
          end

          context "with an attribute type=\"file\"" do
            before do
              @string = '<tag type="file" name="data.txt" content_type="text/plain">ZGF0YQ==</tag>'
            end

            it "should be a StringIO" do
              MultiXml.parse(@string)['tag'].should be_a(StringIO)
            end

            it "should be decoded correctly" do
              MultiXml.parse(@string)['tag'].string.should == 'data'
            end

            it "should have the correct file name" do
              MultiXml.parse(@string)['tag'].original_filename.should == 'data.txt'
            end

            it "should have the correct content type" do
              MultiXml.parse(@string)['tag'].content_type.should == 'text/plain'
            end

            context "with missing name and content type" do
              before do
                @string = '<tag type="file">ZGF0YQ==</tag>'
              end

              it "should be a StringIO" do
                MultiXml.parse(@string)['tag'].should be_a(StringIO)
              end

              it "should be decoded correctly" do
                MultiXml.parse(@string)['tag'].string.should == 'data'
              end

              it "should have the default file name" do
                MultiXml.parse(@string)['tag'].original_filename.should == 'untitled'
              end

              it "should have the default content type" do
                MultiXml.parse(@string)['tag'].content_type.should == 'application/octet-stream'
              end
            end
          end

          context "with an unrecognized attribute type" do
            before do
              @string = '<tag type="foo"/>'
            end

            it "should pass through the type" do
              pending
              MultiXml.parse(@string)['tag']['type'].should == 'foo'
            end
          end

          %w(integer boolean date datetime yaml).each do |type|
            context "with an empty attribute type=\"#{type}\"" do
              before do
                @string = "<tag type=\"#{type}\"/>"
              end

              it "should be nil" do
                MultiXml.parse(@string)['tag'].should be_nil
              end
            end
          end

          context "with an empty attribute type=\"array\"" do
            before do
              @string = '<users type="array"/>'
            end

            it "should be an empty Array" do
              MultiXml.parse(@string)['users'].should == []
            end

            context "with whitespace" do
              before do
                @string = '<users type="array"> </users>'
              end

              it "should be an empty Array" do
                MultiXml.parse(@string)['users'].should == []
              end
            end
          end

          context "with XML entities" do
            before do
              @xml_entities = {
                "<" => "&lt;",
                ">" => "&gt;",
                '"' => "&quot;",
                "'" => "&apos;",
                "&" => "&amp;"
              }
            end

            context "in content" do
              it "should unescape XML entities" do
                @xml_entities.each do |key, value|
                  string = "<tag>#{value}</tag>"
                  MultiXml.parse(string)['tag'].should == key
                end
              end
            end

            context "in attribute" do
              it "should unescape XML entities" do
                @xml_entities.each do |key, value|
                  string = "<tag attribute=\"#{value}\"/>"
                  MultiXml.parse(string)['tag']['attribute'].should == key
                end
              end
            end
          end

          context "with dasherized tag" do
            before do
              @string = '<tag-1/>'
            end

            it "should undasherize tag" do
              MultiXml.parse(@string).keys.should include('tag_1')
            end
          end

          context "with dasherized attribute" do
            before do
              @string = '<tag attribute-1="1"></tag>'
            end

            it "should undasherize attribute" do
              MultiXml.parse(@string)['tag'].keys.should include('attribute_1')
            end
          end
        end

        context "a document" do
          context "with :symbolize_keys => true" do
            before do
              @string = '<user><name>Erik Michaels-Ober</name></user>'
            end

            it "should symbolize keys" do
              MultiXml.parse(@string, :symbolize_keys => true).should == {:user => {:name => "Erik Michaels-Ober"}}
            end
          end

          context "with children" do
            before do
              @string = '<root><user name="Erik Michaels-Ober"/></root>'
            end

            it "should parse correctly" do
              MultiXml.parse(@string).should == {"root" => {"user" => {"name"=>"Erik Michaels-Ober"}}}
            end

            context "with text" do
              before do
                @string = '<user><name>Erik Michaels-Ober</name></user>'
              end

              it "should parse correctly" do
                MultiXml.parse(@string).should == {"user" => {"name" => "Erik Michaels-Ober"}}
              end
            end

            # Babies having babies
            context "with children" do
              before do
                @string = '<root><user name="Erik Michaels-Ober"><status text="Hello"/></user></root>'
              end

              it "should parse correctly" do
                MultiXml.parse(@string).should == {"root" => {"user" => {"name" => "Erik Michaels-Ober", "status" => {"text" => "Hello"}}}}
              end
            end
          end

          context "with sibling children" do
            before do
              @string = '<root><users>Erik Michaels-Ober</users><users>Wynn Netherland</users></root>'
            end

            it "should parse correctly" do
              MultiXml.parse(@string).should == {"root" => {"users" => ["Erik Michaels-Ober", "Wynn Netherland"]}}
            end

            it "should make an Array of children" do
              MultiXml.parse(@string)['root']['users'].should be_a(Array)
            end

          end
        end
      end
    end
  end
end
