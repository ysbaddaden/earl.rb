Gem::Specification.new do |s|
  s.name        = "earl"
  s.version     = "0.1.0"
  s.date        = "2019-10-31"
  s.summary     = "Hola!"
  s.description = "Service objects for Ruby (Agents, Artists, Supervisors, Pools, ...)"
  s.authors     = ["Julien Portalier"]
  s.email       = "julien@portalier.com"
  s.files       = ["lib/earl.rb"]
  s.homepage    = "https://rubygems.org/gems/hola"
  s.license     = "MIT"

  s.add_runtime_dependency "async", "~> 1.23"
  s.add_development_dependency "minitest", "~> 5.0"
end
