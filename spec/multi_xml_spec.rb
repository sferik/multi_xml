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
          pending "Engine #{engine} couldn't be loaded (not installed?)"
        end
      end

      describe '.parse' do
        it 'should properly parse some XML' do
          MultiXml.parse('<tag>This is the contents</tag>').should == {'tag' => 'This is the contents'}
        end

        it 'should allow for symbolization of keys' do
          MultiXml.parse('<tag>This is the contents</tag>', :symbolize_keys => true).should == {:tag => 'This is the contents'}
        end
      end
    end
  end
end
