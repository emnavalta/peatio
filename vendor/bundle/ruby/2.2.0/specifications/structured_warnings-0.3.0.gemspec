# -*- encoding: utf-8 -*-
# stub: structured_warnings 0.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "structured_warnings"
  s.version = "0.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Gregor Schmidt"]
  s.date = "2017-03-23"
  s.description = "This is an implementation of Daniel Berger's proposal of structured warnings for Ruby."
  s.email = ["schmidt@nach-vorne.eu"]
  s.homepage = "http://github.com/schmidt/structured_warnings"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.4.5"
  s.summary = "Provides structured warnings for Ruby, using an exception-like interface and hierarchy"

  s.installed_by_version = "2.4.5" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>, ["~> 1.14"])
      s.add_development_dependency(%q<rake>, ["~> 10.0"])
      s.add_development_dependency(%q<minitest>, ["~> 5.0"])
      s.add_development_dependency(%q<test-unit>, ["~> 3.2"])
    else
      s.add_dependency(%q<bundler>, ["~> 1.14"])
      s.add_dependency(%q<rake>, ["~> 10.0"])
      s.add_dependency(%q<minitest>, ["~> 5.0"])
      s.add_dependency(%q<test-unit>, ["~> 3.2"])
    end
  else
    s.add_dependency(%q<bundler>, ["~> 1.14"])
    s.add_dependency(%q<rake>, ["~> 10.0"])
    s.add_dependency(%q<minitest>, ["~> 5.0"])
    s.add_dependency(%q<test-unit>, ["~> 3.2"])
  end
end
