# frozen_string_literal: true
$LOAD_PATH.unshift "lib"
$LOAD_PATH.unshift "test"

task :test do
  Dir.glob("test/**/*_test.rb").each do |path|
    require_relative path
  end
end

desc "Run tests"
task :default => :test
