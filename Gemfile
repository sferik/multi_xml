source 'https://rubygems.org'

gem 'rake'
gem 'yard'

gem 'libxml-ruby', :require => nil, :platforms => :ruby
gem 'nokogiri', '~> 1.5.0', :require => nil
gem 'ox', :require => nil, :platforms => :ruby

group :development do
  gem 'kramdown'
  gem 'pry'
  gem 'pry-rescue'
  platforms :ruby_19, :ruby_20 do
    gem 'pry-debugger'
    gem 'pry-stack_explorer'
  end
end

group :test do
  gem 'backports'
  gem 'coveralls', :require => false
  gem 'json', :platforms => [:rbx, :ruby_19]
  gem 'mime-types', '~> 1.25', :platforms => [:jruby, :ruby_18]
  gem 'rspec', '>= 2.14'
  gem 'rubocop', '>= 0.16', :platforms => [:ruby_19, :ruby_20, :ruby_21]
  gem 'simplecov', :require => false
  gem 'yardstick'
end

gemspec
