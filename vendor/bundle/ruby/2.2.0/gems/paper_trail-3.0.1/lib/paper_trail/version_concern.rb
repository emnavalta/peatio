require 'active_support/concern'

module PaperTrail
  module VersionConcern
    extend ::ActiveSupport::Concern

    included do
      belongs_to :item, :polymorphic => true
      validates_presence_of :event
      attr_accessible :item_type, :item_id, :event, :whodunnit, :object, :object_changes if PaperTrail.active_record_protected_attributes?

      after_create :enforce_version_limit!
    end

    module ClassMethods
      def with_item_keys(item_type, item_id)
        where :item_type => item_type, :item_id => item_id
      end

      def creates
        where :event => 'create'
      end

      def updates
        where :event => 'update'
      end

      def destroys
        where :event => 'destroy'
      end

      def not_creates
        where 'event <> ?', 'create'
      end

      # These methods accept a timestamp or a version and returns other versions that come before or after
      def subsequent(obj)
        obj = obj.send(PaperTrail.timestamp_field) if obj.is_a?(self)
        where("#{table_name}.#{PaperTrail.timestamp_field} > ?", obj).
          order("#{table_name}.#{PaperTrail.timestamp_field} ASC")
      end

      def preceding(obj)
        obj = obj.send(PaperTrail.timestamp_field) if obj.is_a?(self)
        where("#{table_name}.#{PaperTrail.timestamp_field} < ?", obj).
          order("#{table_name}.#{PaperTrail.timestamp_field} DESC")
      end

      def between(start_time, end_time)
        where("#{table_name}.#{PaperTrail.timestamp_field} > ? AND #{table_name}.#{PaperTrail.timestamp_field} < ?",
          start_time, end_time).order("#{table_name}.#{PaperTrail.timestamp_field} ASC")
      end

      # Returns whether the `object` column is using the `json` type supported by PostgreSQL
      def object_col_is_json?
        @object_col_is_json ||= columns_hash['object'].type == :json
      end

      # Returns whether the `object_changes` column is using the `json` type supported by PostgreSQL
      def object_changes_col_is_json?
        @object_changes_col_is_json ||= columns_hash['object_changes'].type == :json
      end
    end

    # Restore the item from this version.
    #
    # This will automatically restore all :has_one associations as they were "at the time",
    # if they are also being versioned by PaperTrail.  NOTE: this isn't always guaranteed
    # to work so you can either change the lookback period (from the default 3 seconds) or
    # opt out.
    #
    # Options:
    # :has_one     set to `false` to opt out of has_one reification.
    #              set to a float to change the lookback time (check whether your db supports
    #              sub-second datetimes if you want them).
    def reify(options = {})
      return nil if object.nil?

      without_identity_map do
        options[:has_one] = 3 if options[:has_one] == true
        options.reverse_merge! :has_one => false

        attrs = self.class.object_col_is_json? ? object : PaperTrail.serializer.load(object)

        # Normally a polymorphic belongs_to relationship allows us
        # to get the object we belong to by calling, in this case,
        # `item`.  However this returns nil if `item` has been
        # destroyed, and we need to be able to retrieve destroyed
        # objects.
        #
        # In this situation we constantize the `item_type` to get hold of
        # the class...except when the stored object's attributes
        # include a `type` key.  If this is the case, the object
        # we belong to is using single table inheritance and the
        # `item_type` will be the base class, not the actual subclass.
        # If `type` is present but empty, the class is the base class.

        if item
          model = item
          # Look for attributes that exist in the model and not in this version. These attributes should be set to nil.
          (model.attribute_names - attrs.keys).each { |k| attrs[k] = nil }
        else
          inheritance_column_name = item_type.constantize.inheritance_column
          class_name = attrs[inheritance_column_name].blank? ? item_type : attrs[inheritance_column_name]
          klass = class_name.constantize
          model = klass.new
        end

        model.class.unserialize_attributes_for_paper_trail attrs

        # Set all the attributes in this version on the model
        attrs.each do |k, v|
          if model.respond_to?("#{k}=")
            model[k.to_sym] = v
          else
            logger.warn "Attribute #{k} does not exist on #{item_type} (Version id: #{id})."
          end
        end

        model.send "#{model.class.version_association_name}=", self

        unless options[:has_one] == false
          reify_has_ones model, options[:has_one]
        end

        model
      end
    end

    # Returns what changed in this version of the item.  Cf. `ActiveModel::Dirty#changes`.
    # Returns `nil` if your `versions` table does not have an `object_changes` text column.
    def changeset
      return nil unless self.class.column_names.include? 'object_changes'

      _changes = self.class.object_changes_col_is_json? ? object_changes : PaperTrail.serializer.load(object_changes)
      @changeset ||= HashWithIndifferentAccess.new(_changes).tap do |changes|
        item_type.constantize.unserialize_attribute_changes(changes)
      end
    rescue
      {}
    end

    # Returns who put the item into the state stored in this version.
    def originator
      @originator ||= previous.whodunnit rescue nil
    end

    # Returns who changed the item from the state it had in this version.
    # This is an alias for `whodunnit`.
    def terminator
      @terminator ||= whodunnit
    end
    alias_method :version_author, :terminator

    def sibling_versions(reload = false)
      @sibling_versions = nil if reload == true
      @sibling_versions ||= self.class.with_item_keys(item_type, item_id)
    end

    def next
      @next ||= sibling_versions.subsequent(self).first
    end

    def previous
      @previous ||= sibling_versions.preceding(self).first
    end

    def index
      table_name = self.class.table_name
      @index ||= sibling_versions.
        select(["#{table_name}.#{PaperTrail.timestamp_field}", "#{table_name}.#{self.class.primary_key}"]).
        order("#{table_name}.#{PaperTrail.timestamp_field} ASC").index(self)
    end

    private

    # In Rails 3.1+, calling reify on a previous version confuses the
    # IdentityMap, if enabled. This prevents insertion into the map.
    def without_identity_map(&block)
      if defined?(::ActiveRecord::IdentityMap) && ::ActiveRecord::IdentityMap.respond_to?(:without)
        ::ActiveRecord::IdentityMap.without(&block)
      else
        block.call
      end
    end

    # Restore the `model`'s has_one associations as they were when this version was
    # superseded by the next (because that's what the user was looking at when they
    # made the change).
    #
    # The `lookback` sets how many seconds before the model's change we go.
    def reify_has_ones(model, lookback)
      model.class.reflect_on_all_associations(:has_one).each do |assoc|
        child = model.send assoc.name
        if child.respond_to? :version_at
          # N.B. we use version of the child as it was `lookback` seconds before the parent was updated.
          # Ideally we want the version of the child as it was just before the parent was updated...
          # but until PaperTrail knows which updates are "together" (e.g. parent and child being
          # updated on the same form), it's impossible to tell when the overall update started;
          # and therefore impossible to know when "just before" was.
          if (child_as_it_was = child.version_at(send(PaperTrail.timestamp_field) - lookback.seconds))
            child_as_it_was.attributes.each do |k,v|
              model.send(assoc.name).send :write_attribute, k.to_sym, v rescue nil
            end
          else
            model.send "#{assoc.name}=", nil
          end
        end
      end
    end

    # checks to see if a value has been set for the `version_limit` config option, and if so enforces it
    def enforce_version_limit!
      return unless PaperTrail.config.version_limit.is_a? Numeric
      previous_versions = sibling_versions.not_creates
      return unless previous_versions.size > PaperTrail.config.version_limit
      excess_previous_versions = previous_versions - previous_versions.last(PaperTrail.config.version_limit)
      excess_previous_versions.map(&:destroy)
    end
  end
end
