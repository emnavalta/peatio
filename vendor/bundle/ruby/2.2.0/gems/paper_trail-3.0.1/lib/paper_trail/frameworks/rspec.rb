require 'rspec/core'
require 'rspec/matchers'
require 'paper_trail/frameworks/rspec/helpers'

RSpec.configure do |config|
  config.include ::PaperTrail::RSpec::Helpers::InstanceMethods
  config.extend ::PaperTrail::RSpec::Helpers::ClassMethods

  config.before(:each) do
    ::PaperTrail.enabled = false
    ::PaperTrail.enabled_for_controller = true
    ::PaperTrail.whodunnit = nil
    ::PaperTrail.controller_info = {} if defined?(::Rails) && defined?(::RSpec::Rails)
  end

  config.before(:each, :versioning => true) do
    ::PaperTrail.enabled = true
  end
end

RSpec::Matchers.define :be_versioned do
  # check to see if the model has `has_paper_trail` declared on it
  match { |actual| actual.kind_of?(::PaperTrail::Model::InstanceMethods) }
end
