require 'rexml/parsers/baseparser' unless defined?(REXML::Parsers::BaseParser)
require 'rexml/text' unless defined?(REXML::Text)

module MultiXml
  module Parsers
    # Use REXML to parse XML.
    class Rexml

      def self.parse(string, options = {}) #:nodoc:
        stack = []
        parser = ::REXML::Parsers::BaseParser.new(string)

        while true
          event = parser.pull
          case event[0]
          when :end_document
            break
          when :start_element
            stack.push MultiXml::UtilityNode.new(event[1], event[2])
          when :end_element
            if stack.size > 1
              temp = stack.pop
              stack.last.add_node(temp)
            end
          when :text, :cdata
            stack.last.add_node(event[1]) unless event[1].strip.length == 0 || stack.empty?
          end
        end
        hash = (stack.length > 0 ? stack.pop.to_hash : {})
        options[:symbolize_keys] ? MultiXml.symbolize_keys(hash) : hash
      end

    end
  end
end
