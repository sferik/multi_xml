# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'multi_xml/version'

Gem::Specification.new do |spec|
  spec.author = 'Erik Michaels-Ober'
  spec.description = 'Provides swappable XML backends utilizing LibXML, Nokogiri, Ox, or REXML.'
  spec.email = 'sferik@gmail.com'
  spec.files = %w(.yardopts CHANGELOG.md CONTRIBUTING.md LICENSE.md README.md multi_xml.gemspec) + Dir['lib/**/*.rb']
  spec.homepage = 'https://github.com/sferik/multi_xml'
  spec.licenses = ['MIT']
  spec.name = 'multi_xml'
  spec.require_paths = ['lib']
  spec.required_ruby_version     = '>= 3.0'
  spec.summary = 'A generic swappable back-end for XML parsing'
  spec.version = MultiXml::Version
end
