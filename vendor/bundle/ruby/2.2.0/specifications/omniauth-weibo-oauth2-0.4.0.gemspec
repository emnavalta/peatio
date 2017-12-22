# -*- encoding: utf-8 -*-
# stub: omniauth-weibo-oauth2 0.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "omniauth-weibo-oauth2"
  s.version = "0.4.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Bin He"]
  s.date = "2014-12-23"
  s.description = "OmniAuth Oauth2 strategy for weibo.com."
  s.email = "beenhero@gmail.com"
  s.homepage = "https://github.com/beenhero/omniauth-weibo-oauth2"
  s.rubygems_version = "2.4.5"
  s.summary = "OmniAuth Oauth2 strategy for weibo.com."

  s.installed_by_version = "2.4.5" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<omniauth>, ["~> 1.0"])
      s.add_runtime_dependency(%q<omniauth-oauth2>, ["~> 1.0"])
    else
      s.add_dependency(%q<omniauth>, ["~> 1.0"])
      s.add_dependency(%q<omniauth-oauth2>, ["~> 1.0"])
    end
  else
    s.add_dependency(%q<omniauth>, ["~> 1.0"])
    s.add_dependency(%q<omniauth-oauth2>, ["~> 1.0"])
  end
end
