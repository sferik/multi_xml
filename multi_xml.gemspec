# encoding: utf-8
require File.expand_path('../lib/multi_xml/version', __FILE__)

Gem::Specification.new do |spec|
  spec.add_development_dependency 'bundler', '~> 1.0'
  spec.author = "Erik Michaels-Ober"
  spec.description = %q{Provides swappable XML backends utilizing LibXML, Nokogiri, Ox, or REXML.}
  spec.email = 'sferik@gmail.com'
  spec.files = %w(CONTRIBUTING.md LICENSE.md README.md Rakefile multi_xml.gemspec)
  spec.files += Dir.glob("lib/**/*.rb")
  spec.files += Dir.glob("spec/**/*")
  spec.homepage = 'https://github.com/sferik/multi_xml'
  spec.licenses = ['MIT']
  spec.name = 'multi_xml'
  spec.platform = Gem::Platform::RUBY
  spec.require_paths = ['lib']
  spec.summary = %q{A generic swappable back-end for XML parsing}
  spec.test_files = Dir.glob("spec/**/*")
  spec.version = MultiXml::VERSION
end
