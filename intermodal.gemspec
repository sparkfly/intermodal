# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "intermodal/version"

Gem::Specification.new do |s|
  s.name = "intermodal"
  s.version = Intermodal::VERSION
  s.authors = ["Ho-Sheng Hsiao"]
  s.email = %w{hosh@sparkfly.com}

  s.date = %q{2011-08-26}

  s.rubygems_version = %q{1.3.7}
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=

  s.homepage = %q{http://github.com/intermodal/intermodal}
  s.summary = %q{Intermodal lets you quickly put together a pure, JSON/XML-only RESTful web service.}
  s.description = %q{Declarative DSL for top-level, nested, linked CRUD resource endpoints; DSL for Presenters and Acceptors; API Versioning}
  s.rubyforge_project = "intermodal"

  s.files = `git ls-files`.split("\n")

  s.extra_rdoc_files = %w(LICENSE README)
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = %w(lib)


  s.add_runtime_dependency 'rails', '~> 4.2.0'
  s.add_runtime_dependency 'responders', '~> 2.1.0'
  s.add_runtime_dependency 'will_paginate', '>= 3.0.0'
  s.add_runtime_dependency 'warden'

  s.add_development_dependency 'awesome_print'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'rspec-core'
  s.add_development_dependency 'multi_json'
  s.add_development_dependency 'yajl-ruby'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'machinist', '>= 2.0.0.beta2'
  s.add_development_dependency 'faker'
  s.add_development_dependency 'forgery'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'pg'
  s.add_development_dependency 'redis'

end
