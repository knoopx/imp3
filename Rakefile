require 'rubygems'
require 'rake'
require 'lib/imp3'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "imp3"
    gem.summary = %Q{Application for batch processing and fixing common issues when dealing with a large iTunes library}
    gem.description = %Q{An application for batch processing and fixing common issues when dealing with a large iTunes library}
    gem.email = "knoopx@gmail.com"
    gem.homepage = "http://github.com/knoopx/imp3"
    gem.authors = ["Víctor Martínez"]
    gem.add_dependency('commander', '~> 4.0.2')
    gem.add_dependency('terminal-table', '~> 1.4.2')
    gem.add_dependency('nokogiri', '~> 1.4.1')
    gem.add_dependency('pbosetti-rubyosa', '~> 0.5.3')
    gem.add_dependency('friendly_id', '~> 2.3.3')
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = false
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "imp3 #{IMP3::VERSION}"
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
