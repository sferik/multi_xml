source 'https://rubygems.org'

gem 'rake'
gem 'yard'

gem 'libxml-ruby', :require => nil, :platforms => :ruby
gem 'nokogiri', '~> 1.5.0', :require => nil
gem 'ox', :require => nil, :platforms => :ruby

group :development do
  gem 'kramdown'
  gem 'pry'
end

group :test do
  gem 'backports'
  gem 'coveralls'
  gem 'json', :platforms => [:rbx, :ruby_19]
  gem 'mime-types', '~> 1.25', :platforms => [:jruby, :ruby_18]
  gem 'rest-client', '~> 1.6.0', :platforms => [:jruby, :ruby_18]
  gem 'rspec', '>= 2.14'
  # Go back to using the RuboCop gem after https://github.com/bbatsov/rubocop/pull/1956 is released
  gem 'rubocop', :git => 'https://github.com/bbatsov/rubocop.git', :ref => 'f8fbd50e02a19669727bd3a811419b7df6337b4b', :platforms => [:ruby_19, :ruby_20, :ruby_21]
  gem 'simplecov', '>= 0.9'
  gem 'yardstick'
end

gemspec
