# frozen_string_literal: true
require "rake/testtask"

SUB_OPTS =
  if index = ARGV.index("--")
    ARGV[(index + 1)..-1].join(" ")
  end

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]

  if index = ARGV.index("--")
    t.options = ARGV[(index + 1)..-1].join(" ")
  end
end

desc "Run tests"
task :default => :test

desc "Format source files"
task :format do
  sh "bundle exec rufo #{SUB_OPTS} *file *.gemspec lib samples test"
end

desc "Run static analysis"
task :lint do
  sh "bundle exec rubocop #{SUB_OPTS}"
end
