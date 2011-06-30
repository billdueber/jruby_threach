# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "jruby_threach"
  gem.homepage = "http://github.com/billdueber/jruby_threach"
  gem.license = "MIT"
  gem.summary = %Q{Very simply run a block of code using multiple threads under jruby}
  gem.description = %Q{Run a block of code in multiple threads. Similar to threach, but with the ability to deal with breaks/exceptions (MRI can't because of unreliable timeouts).}
  gem.email = "bill@dueber.com"
  gem.authors = ["BillDueber"]
  gem.platform = 'java'
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new
