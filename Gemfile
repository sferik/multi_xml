source 'https://rubygems.org'

gem 'rake'
gem 'yard'

gem 'libxml-ruby', :require => nil, :platforms => :ruby
gem 'nokogiri', '~> 1.5.0', :require => nil
gem 'ox', :require => nil, :platforms => :ruby

group :development do
  gem 'kramdown'
  gem 'pry'
  gem 'pry-debugger', :platforms => [:mri_19, :mri_20]
end

group :test do
  gem 'coveralls', :require => false
  gem 'mime-types', '~> 1.25', :platforms => :ruby_18
  gem 'rspec', '>= 2.11'
  gem 'simplecov', :require => false
end

platforms :rbx do
  gem 'racc', '~> 1.4' # Required for testing against Nokogiri on Rubinius
  gem 'rubinius-coverage',  '~> 2.0'
  gem 'rubysl-base64', '~> 2.0'
  gem 'rubysl-bigdecimal', '~> 2.0'
  gem 'rubysl-net-http', '~> 2.0'
  gem 'rubysl-rexml', '~> 2.0'
end

gemspec
