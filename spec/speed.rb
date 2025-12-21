#!/usr/bin/env ruby -wW1

$LOAD_PATH << "."
$LOAD_PATH << "../lib"

if __FILE__ == $PROGRAM_NAME
  while (i = ARGV.index("-I"))
    _, path = ARGV.slice!(i, 2)
    $LOAD_PATH << path
  end
end

require "optparse"
require "stringio"
require "multi_xml"

%w[libxml nokogiri ox].each do |library|
  require library
rescue LoadError
  next
end

module SpeedTest
  class << self
    attr_accessor :verbose, :parsers, :iterations
  end

  self.verbose = 0
  self.parsers = []
  self.iterations = 10

  def self.run(files)
    files.each { |filename| benchmark_file(filename) }
  end

  def self.benchmark_file(filename)
    xml = File.read(filename)
    times = parsers.to_h { |p| [p, time_parser(p, xml)] }
    times.each { |p, t| print_result(p, t, filename) }
  end

  def self.time_parser(parser_name, xml)
    MultiXml.parser = parser_name
    start = Time.now
    iterations.times { MultiXml.parse(StringIO.new(xml)) }
    Time.now - start
  end

  def self.print_result(parser, time, filename)
    puts format("%<parser>8s took %<time>0.3f seconds to parse %<file>s %<iterations>d times.",
      parser: parser, time: time, file: filename, iterations: iterations)
  end

  def self.detect_parsers
    parsers << "libxml" if defined?(::LibXML)
    parsers << "nokogiri" if defined?(::Nokogiri)
    parsers << "ox" if defined?(::Ox)
  end
end

opts = OptionParser.new
opts.on("-v", "increase verbosity") { SpeedTest.verbose += 1 }
opts.on("-p", "--parser [String]", String, "parser to test") { |parser| SpeedTest.parsers = [parser] }
opts.on("-i", "--iterations [Int]", Integer, "iterations") { |iterations| SpeedTest.iterations = iterations }
opts.on("-h", "--help", "Show this display") do
  puts opts
  Process.exit!(0)
end
files = opts.parse(ARGV)

SpeedTest.detect_parsers if SpeedTest.parsers.empty?
SpeedTest.run(files)
