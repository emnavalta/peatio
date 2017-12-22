$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'paper_trail/version_number'

Gem::Specification.new do |s|
  s.name          = 'paper_trail'
  s.version       = PaperTrail::VERSION
  s.platform      = Gem::Platform::RUBY
  s.summary       = "Track changes to your models' data. Good for auditing or versioning."
  s.description   = s.summary
  s.homepage      = 'https://github.com/airblade/paper_trail'
  s.authors       = ['Andy Stewart', 'Ben Atkins']
  s.email         = 'batkinz@gmail.com'
  s.license       = 'MIT'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.required_rubygems_version = '>= 1.3.6'

  s.add_dependency 'activerecord', ['>= 3.0', '< 5.0']
  s.add_dependency 'activesupport', ['>= 3.0', '< 5.0']

  s.add_development_dependency 'rake'
  s.add_development_dependency 'shoulda', '~> 3.5'
  # s.add_development_dependency 'shoulda-matchers', '~> 1.5' # needed for ActiveRecord < 4
  s.add_development_dependency 'ffaker',  '>= 1.15'
  s.add_development_dependency 'railties', ['>= 3.0', '< 5.0']
  s.add_development_dependency 'sinatra', '~> 1.0'
  s.add_development_dependency 'rack-test', '>= 0.6'
  s.add_development_dependency 'rspec-rails', '~> 2.14'
  s.add_development_dependency 'generator_spec'

  # JRuby support for the test ENV
  unless defined?(JRUBY_VERSION)
    s.add_development_dependency 'sqlite3', '~> 1.2'
  else
    s.add_development_dependency 'activerecord-jdbcsqlite3-adapter', '~> 1.3'
  end
end
