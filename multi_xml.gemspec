# -*- encoding: utf-8 -*-
require File.expand_path('../lib/multi_xml/version', __FILE__)

Gem::Specification.new do |gem|
  gem.add_development_dependency 'ZenTest', '~> 4.5'
  gem.add_development_dependency 'maruku', '~> 0.6'
  gem.add_development_dependency 'nokogiri', '~> 1.4'
  gem.add_development_dependency 'rake', '~> 0.8'
  gem.add_development_dependency 'rspec', '~> 2.6'
  gem.add_development_dependency 'simplecov', '~> 0.4'
  # gem.add_development_dependency 'yard', '~> 0.7'
  gem.name = 'multi_xml'
  gem.version = MultiXml::VERSION
  gem.platform = Gem::Platform::RUBY
  gem.author = "Erik Michaels-Ober"
  gem.email = 'sferik@gmail.com'
  gem.homepage = 'https://github.com/sferik/multi_xml'
  gem.summary = %q{A generic swappable back-end for XML parsing}
  gem.description = %q{A gem to provide swappable XML backends utilizing LibXML, Nokogiri, or REXML.}
  gem.files = `git ls-files`.split("\n")
  gem.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.require_paths = ['lib']
end
