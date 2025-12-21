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

$verbose = 0
$parsers = []
$iterations = 10

opts = OptionParser.new
opts.on("-v", "increase verbosity") { $verbose += 1 }
opts.on("-p", "--parser [String]", String, "parser to test") { |parsers| $parsers = [parsers] }
opts.on("-i", "--iterations [Int]", Integer, "iterations") { |iterations| $iterations = iterations }
opts.on("-h", "--help", "Show this display") do
  puts opts
  Process.exit!(0)
end
files = opts.parse(ARGV)

if $parsers.empty?
  $parsers << "libxml" if defined?(::LibXML)
  $parsers << "nokogiri" if defined?(::Nokogiri)
  $parsers << "ox" if defined?(::Ox)
end

files.each do |filename|
  times = {}
  xml = File.read(filename)
  $parsers.each do |p|
    MultiXml.parser = p
    start = Time.now
    $iterations.times do
      io = StringIO.new(xml)
      MultiXml.parse(io)
    end
    times[p] = Time.now - start
  end
  times.each do |p, t|
    puts format("%<parser>8s took %<time>0.3f seconds to parse %<file>s %<iterations>d times.",
      parser: p, time: t, file: filename, iterations: $iterations)
  end
end
