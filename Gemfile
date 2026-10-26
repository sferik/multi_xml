source "https://rubygems.org"

gem "libxml-ruby", require: nil, platforms: :ruby
gem "nokogiri", require: nil
gem "oga", ">= 2.3", require: nil
gem "ox", require: nil, platforms: :ruby
gem "rexml", require: nil

gem "minitest", ">= 6"
gem "minitest-mock", ">= 5.27"
gem "mutant-minitest", ">= 0.14.1"
gem "rake", ">= 13.3.1"
gem "rbs", ">= 4.0.0", platforms: :ruby
if RUBY_ENGINE == "jruby"
  # rdoc 8 depends on rbs, whose native extension does not build on JRuby
  gem "rdoc", ">= 7.0.2", "< 8"
else
  gem "rdoc", ">= 7.0.2"
end
gem "rubocop", ">= 1.81.7"
gem "rubocop-minitest", ">= 0.36"
gem "rubocop-performance", ">= 1.26.1"
gem "rubocop-rake", ">= 0.7.1"
gem "simplecov", ">= 1"
gem "standard", ">= 1.52"
gem "standard-performance", ">= 1.9"
gem "steep", ">= 2", platforms: :ruby
gem "yard", ">= 0.9.38"
gem "yardstick", ">= 0.9.9"

group :development do
  # Duel requires Ruby 3.4 or later
  gem "duel", ">= 0.1.1" if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.4")
  gem "stackprof", platforms: :mri
end

gemspec
