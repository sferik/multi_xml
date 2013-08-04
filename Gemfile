source 'https://rubygems.org'

gem 'rake'
gem 'yard'

gem 'libxml-ruby', :require => nil, :platforms => :mri
gem 'nokogiri', '~> 1.5.0', :require => nil
gem 'ox', :require => nil

group :development do
  gem 'kramdown'
  gem 'pry'
  gem 'pry-debugger', :platforms => :mri_19
end

group :test do
  gem 'coveralls', :require => false
  gem 'rspec', '>= 2.11'
  gem 'simplecov', :require => false
end

gemspec
