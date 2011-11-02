# encoding: utf-8
require File.expand_path('../lib/multi_xml/version', __FILE__)

Gem::Specification.new do |gem|
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rdiscount'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'simplecov'
  gem.add_development_dependency 'yard'
  gem.author = "Erik Michaels-Ober"
  gem.description = %q{A gem to provide swappable XML backends utilizing LibXML, Nokogiri, Ox, or REXML.}
  gem.email = 'sferik@gmail.com'
  gem.files = `git ls-files`.split("\n")
  gem.homepage = 'https://github.com/sferik/multi_xml'
  gem.name = 'multi_xml'
  gem.platform = Gem::Platform::RUBY
  gem.require_paths = ['lib']
  gem.summary = %q{A generic swappable back-end for XML parsing}
  gem.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.version = MultiXml::VERSION
end
