# before hook for Cucumber
Before do
  PaperTrail.enabled = false
  PaperTrail.enabled_for_controller = true
  PaperTrail.whodunnit = nil
  PaperTrail.controller_info = {} if defined? Rails
end

module PaperTrail
  module Cucumber
    module Extensions
      # :call-seq:
      # with_versioning
      #
      # enable versioning for specific blocks

      def with_versioning
        was_enabled = ::PaperTrail.enabled?
        ::PaperTrail.enabled = true
        begin
          yield
        ensure
          ::PaperTrail.enabled = was_enabled
        end
      end
    end
  end
end

World PaperTrail::Cucumber::Extensions
