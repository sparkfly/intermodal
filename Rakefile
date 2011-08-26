require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rspec/core/rake_task'

desc 'Default: run specs.'
task :default => :spec

desc 'Run the specs'
RSpec::Core::RakeTask.new(:spec) do |t|
  #t.spec_opts = ['--colour --format progress --loadby mtime --reverse']
  #t.spec_files = FileList['spec/**/*_spec.rb']
end

desc 'Generate documentation for the foreigner plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Intermodal'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "intermodal"
    gemspec.summary = "Intermodal lets you quickly put together a pure, JSON/XML-only RESTful web service."
    gemspec.description = "Declarative DSL for top-level, nested, linked CRUD resource endpoints; DSL for Presenters and Acceptors; API Versioning"
    gemspec.email = "hosh@sparkfly.com"
    gemspec.homepage = "http://github.com/hosh/intermodal"
    gemspec.authors = ["Ho-Sheng Hsiao"]

    gemspec.add_dependency 'will_paginate', '>=3.0.0'
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end

