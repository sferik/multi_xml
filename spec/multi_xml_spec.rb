require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class MockDecoder
  def self.parse(string)
    '<tag>This is the contents</tag>'
  end
end

describe "MultiXml" do
  context 'engines' do
    it 'should default to the best available gem' do
      pending
      require 'libxml'
      MultiXml.engine.name.should == 'MultiXml::Engines::Libxml'
    end

    it 'should be settable via a symbol' do
      pending
      MultiXml.engine = :libxml
      MultiXml.engine.name.should == 'MultiXml::Engines::Libxml'
    end

    it 'should be settable via a class' do
      MultiXml.engine = MockDecoder
      MultiXml.engine.name.should == 'MockDecoder'
    end
  end

  %w(libxml nokogiri hpricot rexml).each do |engine|
    context engine do
      before do
        begin
          MultiXml.engine = engine
        rescue LoadError
          pending "Engine #{engine} couldn't be loaded"
        end
      end

      describe '.parse' do
        it 'should return an empty hash for blank string' do
          MultiXml.parse('').should == {}
        end

        it 'should return an empty hash for single space string' do
          MultiXml.parse(' ').should == {}
        end

        it 'should properly parse a single-node document' do
          MultiXml.parse('<user/>').should == {'user' => nil}
        end

        it 'should propertly parse a single-node document with content' do
          MultiXml.parse('<user>Erik Michaels-Ober</user>').should == {"user" => "Erik Michaels-Ober"}
        end

        it 'should properly parse a single-node document an attribute' do
          MultiXml.parse('<user name="Erik Michaels-Ober"/>').should == {"user" => {"name" => "Erik Michaels-Ober"}}
        end

        it 'should properly parse a single-node document attributes' do
          MultiXml.parse('<user name="Erik Michaels-Ober" screen_name="sferik"/>').should == {"user" => {"name" => "Erik Michaels-Ober", "screen_name" => "sferik"}}
        end

        it 'should properly parse children' do
          MultiXml.parse('<users type="array"><user name="Erik Michaels-Ober"/></users>').should == {"users" => [{"name" => "Erik Michaels-Ober"}]}
        end

        it 'should propertly parse children with children' do
          MultiXml.parse('<users type="array"><user name="Erik Michaels-Ober"><status text="Hello"/></user></users>').should == {"users" => [{"name" => "Erik Michaels-Ober", "status" => {"text" => "Hello"}}]}
        end

        it 'should propertly parse children with text' do
          MultiXml.parse('<user><name>Erik Michaels-Ober</name></user>').should == {"user" => {"name" => "Erik Michaels-Ober"}}
        end

        it 'should allow symbolization of keys' do
          MultiXml.parse('<user><name>Erik Michaels-Ober</name></user>', :symbolize_keys => true).should == {:user => {:name => "Erik Michaels-Ober"}}
        end

      end
    end
  end
end
