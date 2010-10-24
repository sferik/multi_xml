$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'multi_xml'
require 'rspec/core'
require 'rubygems'
require 'bundler'
Bundler.setup
