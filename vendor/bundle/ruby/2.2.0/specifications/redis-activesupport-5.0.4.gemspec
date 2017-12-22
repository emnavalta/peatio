# -*- encoding: utf-8 -*-
# stub: redis-activesupport 5.0.4 ruby lib

Gem::Specification.new do |s|
  s.name = "redis-activesupport"
  s.version = "5.0.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Luca Guidi", "Ryan Bigg"]
  s.date = "2017-10-16"
  s.description = "Redis store for ActiveSupport"
  s.email = ["me@lucaguidi.com", "me@ryanbigg.com"]
  s.homepage = "http://redis-store.org/redis-activesupport"
  s.licenses = ["MIT"]
  s.rubyforge_project = "redis-activesupport"
  s.rubygems_version = "2.4.5"
  s.summary = "Redis store for ActiveSupport"

  s.installed_by_version = "2.4.5" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<redis-store>, ["< 2", ">= 1.3"])
      s.add_runtime_dependency(%q<activesupport>, ["< 6", ">= 3"])
      s.add_development_dependency(%q<rake>, ["~> 10"])
      s.add_development_dependency(%q<bundler>, ["~> 1.3"])
      s.add_development_dependency(%q<mocha>, ["~> 0.14.0"])
      s.add_development_dependency(%q<minitest>, ["< 6", ">= 4.2"])
      s.add_development_dependency(%q<connection_pool>, ["~> 2.2.0"])
      s.add_development_dependency(%q<redis-store-testing>, [">= 0"])
    else
      s.add_dependency(%q<redis-store>, ["< 2", ">= 1.3"])
      s.add_dependency(%q<activesupport>, ["< 6", ">= 3"])
      s.add_dependency(%q<rake>, ["~> 10"])
      s.add_dependency(%q<bundler>, ["~> 1.3"])
      s.add_dependency(%q<mocha>, ["~> 0.14.0"])
      s.add_dependency(%q<minitest>, ["< 6", ">= 4.2"])
      s.add_dependency(%q<connection_pool>, ["~> 2.2.0"])
      s.add_dependency(%q<redis-store-testing>, [">= 0"])
    end
  else
    s.add_dependency(%q<redis-store>, ["< 2", ">= 1.3"])
    s.add_dependency(%q<activesupport>, ["< 6", ">= 3"])
    s.add_dependency(%q<rake>, ["~> 10"])
    s.add_dependency(%q<bundler>, ["~> 1.3"])
    s.add_dependency(%q<mocha>, ["~> 0.14.0"])
    s.add_dependency(%q<minitest>, ["< 6", ">= 4.2"])
    s.add_dependency(%q<connection_pool>, ["~> 2.2.0"])
    s.add_dependency(%q<redis-store-testing>, [">= 0"])
  end
end
