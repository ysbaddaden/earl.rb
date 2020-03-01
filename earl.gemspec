# frozen_string_literal: true
Gem::Specification.new do |s|
  s.name = "earl"
  s.version = "0.1.0"
  s.date = "2019-10-31"

  s.summary = "Service objects for Ruby (Agents, Artists, Supervisors, Pools, ...)"
  s.description = <<~TEXT
    Service objects for Ruby, aka Agents.

    Ruby's async gem provides primitives for achieving concurrent applications,
    but doesn't have advanced layers for structuring applications. Earl fills
    that gap with a simple object-based API that's easy to grasp and understand.
  TEXT

  s.authors = ["Julien Portalier"]
  s.email = "julien@portalier.com"
  s.files = Dir["lib/**/*.rb"]
  s.homepage = "https://rubygems.org/gems/#{s.name}"
  s.license = "MIT"

  s.metadata = {
    "bug_tracker_uri" => "https://github.com/ysbaddaden/earl.rb/issues",
    "changelog_uri" => "https://github.com/ysbaddaden/earl.rb/CHANGELOG.md",
    "documentation_uri" => "https://www.rubydoc.info/gems/#{s.name}/#{s.version}",
    "homepage_uri" => "https://github.com/ysbaddaden/earl.rb",
    "source_code_uri" => "https://github.com/ysbaddaden/earl.rb",
    "wiki_uri" => "https://github.com/ysbaddaden/earl.rb/wiki",
  }

  s.add_runtime_dependency "async", "~> 1.23"
  s.add_development_dependency "minitest", "~> 5.0"
  s.add_development_dependency "rubocop", "~> 0.76"
end
