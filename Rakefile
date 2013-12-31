require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

task :test => :spec

namespace :doc do
  require 'yard'
  YARD::Rake::YardocTask.new do |task|
    task.files   = ['lib/**/*.rb', '-', 'LICENSE.md']
    task.options = [
      '--no-private',
      '--protected',
      '--output-dir', 'doc/yard',
      '--markup', 'markdown',
    ]
  end
end

begin
  require 'rubocop/rake_task'
  Rubocop::RakeTask.new
rescue LoadError
  task :rubocop do
    $stderr.puts 'Rubocop is disabled'
  end
end

task :default => [:spec, :rubocop]
