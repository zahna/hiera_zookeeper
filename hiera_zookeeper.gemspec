Gem::Specification.new do |s|
  s.name        = 'hiera_zookeeper'
  s.version     = '0.2.3'
  s.summary     = "A backend plugin to Hiera to enable it to reference data from Zookeeper."
  s.authors     = ["zahna"]
  s.email       = "scott@zahna.com"
  s.files       = ["lib/hiera/backend/zookeeper_backend.rb"]
  s.homepage    = "https://github.com/zahna/hiera_zookeeper"
  s.required_ruby_version = '>= 1.8.7'
  s.add_runtime_dependency 'hiera', '>= 1.0.0'
  s.add_runtime_dependency 'zookeeper', '>= 1.3.0'
end

