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

require "steep/rake_task"
Steep::RakeTask.new

desc "Run linters"
task lint: %i[rubocop standard]

desc "Run mutation testing"
task :mutant do
  system("bundle", "exec", "mutant", "run") || exit(1)
end

task default: %i[test lint verify_measurements steep mutant]
