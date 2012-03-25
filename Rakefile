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
  gem.name = "sklik-api"
  gem.homepage = "http://github.com/ondrejbartas/sklik-api"
  gem.license = "MIT"
  gem.summary = %Q{Sklik advertising PPC api for creating campaigns}
  gem.description = %Q{Sklik advertising PPC api for creating campaigns and updating them when they runs}
  gem.email = "ondrej@bartas.cz"
  gem.authors = ["Ondrej Bartas"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new


#get directories!
CONF_DIR = File.expand_path(File.join("..", "config"), __FILE__)

#copy example config files for redis and elastic if they don't exists
unless File.exists?(File.join(CONF_DIR, "access.rb")) 
  FileUtils.cp(File.join(CONF_DIR, "access.rb.example"), File.join(CONF_DIR, "access.rb") ) 
  puts "WARNING: you need to setup your config/access.rb -> I created this file for you with example usage"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/unit/*.rb'
  test.verbose = true
end

require 'rcov/rcovtask'
Rcov::RcovTask.new do |test|
  test.libs << 'test'
  test.pattern = 'test/unit/*.rb'
  test.verbose = true
  test.rcov_opts << '--exclude "gems/*"'
end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "sklik-api #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

