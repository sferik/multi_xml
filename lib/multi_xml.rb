module MultiXml
  module_function

  # Get the current engine class.
  def engine
    return @engine if @engine
    self.engine = self.default_engine
    @engine
  end

  REQUIREMENT_MAP = [
    ['libxml', :libxml],
    ['nokogiri', :nokogiri],
    ['hpricot', :hpricot],
    ['rexml/document', :rexml]
  ]

  # The default engine based on what you currently
  # have loaded and installed. First checks to see
  # if any engines are already loaded, then checks
  # to see which are installed if none are loaded.
  def default_engine
    return :libxml if defined?(::LibXML)
    return :nokogiri if defined?(::Nokogiri)
    return :hpricot if defined?(::Hpricot)

    REQUIREMENT_MAP.each do |(library, engine)|
      begin
        require library
        return engine
      rescue LoadError
        next
      end
    end
  end

  # Set the XML parser utilizing a symbol, string, or class.
  # Supported by default are:
  #
  # * <tt>:libxml</tt>
  # * <tt>:nokogiri</tt>
  # * <tt>:hpricot</tt>
  # * <tt>:rexml</tt>
  def engine=(new_engine)
    case new_engine
      when String, Symbol
        require "multi_xml/engines/#{new_engine}"
        @engine = MultiXml::Engines.const_get("#{new_engine.to_s.split('_').map{|s| s.capitalize}.join('')}")
      when Class
        @engine = new_engine
      else
        raise "Did not recognize your engine specification. Please specify either a symbol or a class."
    end
  end

  # Parse a XML string into Ruby.
  #
  # <b>Options</b>
  #
  # <tt>:symbolize_keys</tt> :: If true, will use symbols instead of strings for the keys.
  def parse(string, options = {})
    engine.parse(string, options)
  end

  def symbolize_keys(hash)
    hash.inject({}) do |result, (key, value)|
      new_key = case key
      when String
        key.to_sym
      else
        key
      end
      new_value = case value
      when Hash
        symbolize_keys(value)
      else
        value
      end
      result[new_key] = new_value
      result
    end
  end

end
