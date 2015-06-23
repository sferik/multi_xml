source 'https://rubygems.org'

gem 'rake'
gem 'yard'

gem 'libxml-ruby', :require => nil, :platforms => :ruby
gem 'nokogiri', :require => nil
gem 'ox', :require => nil, :platforms => :ruby
gem 'oga', '~> 1.0', :require => nil

group :development do
  gem 'kramdown'
  gem 'pry'
end

group :test do
  gem 'backports'
  gem 'coveralls'
  gem 'mime-types'
  gem 'rest-client'
  gem 'rspec', '>= 2.14'
  # Go back to using the RuboCop gem after https://github.com/bbatsov/rubocop/pull/1956 is released
  gem 'rubocop', :git => 'https://github.com/bbatsov/rubocop.git', :ref => 'f8fbd50e02a19669727bd3a811419b7df6337b4b'
  gem 'simplecov', '>= 0.9'
  gem 'yardstick'
end

gemspec
