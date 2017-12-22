module PaperTrail
  module Cleaner
    # Destroys all but the most recent version(s) for items on a given date (or on all dates). Useful for deleting drafts.
    #
    # Options:
    # :keeping      An `integer` indicating the number of versions to be kept for each item per date.
    #               Defaults to `1`.
    # :date         Should either be a `Date` object specifying which date to destroy versions for or `:all`,
    #               which will specify that all dates should be cleaned. Defaults to `:all`.
    # :item_id      The `id` for the item to be cleaned on, or `nil`, which causes all items to be cleaned.
    #               Defaults to `nil`.
    def clean_versions!(options = {})
      options = {:keeping => 1, :date => :all}.merge(options)
      gather_versions(options[:item_id], options[:date]).each do |item_id, versions|
        versions.group_by { |v| v.created_at.to_date }.each do |date, versions| # now group the versions by date and iterate through those
          versions.pop(options[:keeping]) # remove the number of versions we wish to keep from the collection of versions prior to destruction
          versions.map(&:destroy)
        end
      end
    end

    private

    # Returns a hash of versions grouped by the `item_id` attribute formatted like this: {:item_id => PaperTrail::Version}.
    # If `item_id` or `date` is set, versions will be narrowed to those pointing at items with those ids that were created on specified date.
    def gather_versions(item_id = nil, date = :all)
      raise "`date` argument must receive a Timestamp or `:all`" unless date == :all || date.respond_to?(:to_date)
      versions = item_id ? PaperTrail::Version.where(:item_id => item_id) : PaperTrail::Version
      versions = versions.between(date.to_date, date.to_date + 1.day) unless date == :all
      versions = PaperTrail::Version.all if versions == PaperTrail::Version # if versions has not been converted to an ActiveRecord::Relation yet, do so now
      versions.group_by(&:item_id)
    end
  end
end
