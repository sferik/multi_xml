# encoding: utf-8
require File.expand_path('../lib/multi_xml/version', __FILE__)

Gem::Specification.new do |spec|
  spec.add_development_dependency 'kramdown'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'yard'
  spec.author = "Erik Michaels-Ober"
  spec.description = %q{Provides swappable XML backends utilizing LibXML, Nokogiri, Ox, or REXML.}
  spec.email = 'sferik@gmail.com'
  spec.files = `git ls-files`.split("\n")
  spec.homepage = 'https://github.com/sferik/multi_xml'
  spec.licenses = ['MIT']
  spec.name = 'multi_xml'
  spec.platform = Gem::Platform::RUBY
  spec.require_paths = ['lib']
  spec.summary = %q{A generic swappable back-end for XML parsing}
  spec.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.version = MultiXml::VERSION
end
