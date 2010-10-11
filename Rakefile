require "bundler"
require "rake/rdoctask"
require "rspec/core/rake_task"

Bundler::GemHelper.install_tasks

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "multi_xml #{MultiXml::VERSION}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc "Run all examples"
RSpec::Core::RakeTask.new(:spec) do |t|
end

task :default => :spec
