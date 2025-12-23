require "bundler"
Bundler::GemHelper.install_tasks

require "rake/testtask"
Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
end

require "standard/rake"
require "rubocop/rake_task"
RuboCop::RakeTask.new

require "yard"
YARD::Rake::YardocTask.new do |task|
  task.files = ["lib/**/*.rb", "-", "LICENSE.md"]
  task.options = [
    "--no-private",
    "--protected",
    "--output-dir", "doc/yard",
    "--markup", "markdown"
  ]
end

require "yardstick/rake/measurement"
Yardstick::Rake::Measurement.new do |measurement|
  measurement.output = "measurement/report.txt"
end

require "yardstick/rake/verify"
Yardstick::Rake::Verify.new do |verify|
  verify.threshold = 100
end

# Steep requires native extensions not available on JRuby or Windows
unless RUBY_PLATFORM == "java" || Gem.win_platform?
  require "steep/rake_task"
  Steep::RakeTask.new
end

desc "Run linters"
task lint: %i[rubocop standard]

# Mutant uses fork() which is not available on Windows or JRuby
desc "Run mutation testing"
task :mutant do
  if Gem.win_platform? || RUBY_PLATFORM == "java"
    puts "Skipping mutant on Windows/JRuby (fork not supported)"
  else
    system("bundle", "exec", "mutant", "run") || exit(1)
  end
end

default_tasks = %i[test lint verify_measurements mutant]
default_tasks << :steep unless RUBY_PLATFORM == "java" || Gem.win_platform?

task default: default_tasks
