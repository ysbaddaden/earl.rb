# frozen_string_literal: true
$LOAD_PATH.unshift "lib"
$LOAD_PATH.unshift "test"

task :test do
  path = ENV.fetch("TESTS") { "test/**/*_test.rb" }

  Dir.glob(path).each do |path|
    require_relative path
  end
end

desc "Run tests"
task :default => :test
