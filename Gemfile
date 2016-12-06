source 'https://rubygems.org'

gem 'rake'
gem 'yard'

gem 'libxml-ruby', :require => nil, :platforms => :ruby
gem 'nokogiri', :require => nil
gem 'oga', '>= 2.3', :require => nil
gem 'ox', :require => nil, :platforms => :ruby

platforms :ruby_19 do
  gem 'json', '~> 1.8'
  gem 'mime-types', '~> 2.99'
  gem 'rest-client', '~> 1.8'
end

group :development do
  gem 'kramdown'
  gem 'pry'
end

group :test do
  gem 'backports'
  gem 'coveralls'
  gem 'rspec', '>= 2.14'
  gem 'rubocop', '~> 0.41.1'
  gem 'simplecov', '>= 0.9'
  gem 'tins', '~> 1.6.0'
  gem 'yardstick'
end

gemspec
