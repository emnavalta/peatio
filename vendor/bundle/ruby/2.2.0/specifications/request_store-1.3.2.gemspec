# -*- encoding: utf-8 -*-
# stub: request_store 1.3.2 ruby lib

Gem::Specification.new do |s|
  s.name = "request_store"
  s.version = "1.3.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Steve Klabnik"]
  s.date = "2017-01-05"
  s.description = "RequestStore gives you per-request global storage."
  s.email = ["steve@steveklabnik.com"]
  s.homepage = "http://github.com/steveklabnik/request_store"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.4.5"
  s.summary = "RequestStore gives you per-request global storage."

  s.installed_by_version = "2.4.5" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>, ["~> 10.5"])
      s.add_development_dependency(%q<minitest>, ["~> 5.0"])
    else
      s.add_dependency(%q<rake>, ["~> 10.5"])
      s.add_dependency(%q<minitest>, ["~> 5.0"])
    end
  else
    s.add_dependency(%q<rake>, ["~> 10.5"])
    s.add_dependency(%q<minitest>, ["~> 5.0"])
  end
end
