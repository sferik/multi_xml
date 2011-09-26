# encoding: utf-8
require File.expand_path('../lib/multi_xml/version', __FILE__)

Gem::Specification.new do |gem|
  gem.add_development_dependency 'libxml-ruby', '~> 2.0' unless RUBY_PLATFORM == 'java'
  gem.add_development_dependency 'nokogiri', '~> 1.4'
  gem.add_development_dependency 'ox', '~> 1.3'
  gem.add_development_dependency 'rake', '~> 0.9'
  gem.add_development_dependency 'rdiscount', '~> 1.6'
  gem.add_development_dependency 'rspec', '~> 2.6'
  gem.add_development_dependency 'simplecov', '~> 0.4'
  gem.add_development_dependency 'yard', '~> 0.7'
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
