require 'multi_json'
require 'set'

module Grape
  # An Entity is a lightweight structure that allows you to easily
  # represent data from your application in a consistent and abstracted
  # way in your API. Entities can also provide documentation for the
  # fields exposed.
  #
  # @example Entity Definition
  #
  #   module API
  #     module Entities
  #       class User < Grape::Entity
  #         expose :first_name, :last_name, :screen_name, :location
  #         expose :field, documentation: { type: "string", desc: "describe the field" }
  #         expose :latest_status, using: API::Status, as: :status, unless: { collection: true }
  #         expose :email, if: { type: :full }
  #         expose :new_attribute, if: { version: 'v2' }
  #         expose(:name) { |model, options| [model.first_name, model.last_name].join(' ') }
  #       end
  #     end
  #   end
  #
  # Entities are not independent structures, rather, they create
  # **representations** of other Ruby objects using a number of methods
  # that are convenient for use in an API. Once you've defined an Entity,
  # you can use it in your API like this:
  #
  # @example Usage in the API Layer
  #
  #   module API
  #     class Users < Grape::API
  #       version 'v2'
  #
  #       desc 'User index', { params: API::Entities::User.documentation }
  #       get '/users' do
  #         @users = User.all
  #         type = current_user.admin? ? :full : :default
  #         present @users, with: API::Entities::User, type: type
  #       end
  #     end
  #   end
  class Entity
    attr_reader :object, :options

    # The Entity DSL allows you to mix entity functionality into
    # your existing classes.
    module DSL
      def self.included(base)
        base.extend ClassMethods
        ancestor_entity_class = base.ancestors.detect { |a| a.entity_class if a.respond_to?(:entity_class) }
        base.const_set(:Entity, Class.new(ancestor_entity_class || Grape::Entity)) unless const_defined?(:Entity)
      end

      module ClassMethods
        # Returns the automatically-created entity class for this
        # Class.
        def entity_class(search_ancestors = true)
          klass = const_get(:Entity) if const_defined?(:Entity)
          klass ||= ancestors.detect { |a| a.entity_class(false) if a.respond_to?(:entity_class) } if search_ancestors
          klass
        end

        # Call this to make exposures to the entity for this Class.
        # Can be called with symbols for the attributes to expose,
        # a block that yields the full Entity DSL (See Grape::Entity),
        # or both.
        #
        # @example Symbols only.
        #
        #   class User
        #     include Grape::Entity::DSL
        #
        #     entity :name, :email
        #   end
        #
        # @example Mixed.
        #
        #   class User
        #     include Grape::Entity::DSL
        #
        #     entity :name, :email do
        #       expose :latest_status, using: Status::Entity, if: :include_status
        #       expose :new_attribute, if: { version: 'v2' }
        #     end
        #   end
        def entity(*exposures, &block)
          entity_class.expose(*exposures) if exposures.any?
          entity_class.class_eval(&block) if block_given?
          entity_class
        end
      end

      # Instantiates an entity version of this object.
      def entity(options = {})
        self.class.entity_class.new(self, options)
      end
    end

    # This method is the primary means by which you will declare what attributes
    # should be exposed by the entity.
    #
    # @option options :as Declare an alias for the representation of this attribute.
    # @option options :if When passed a Hash, the attribute will only be exposed if the
    #   runtime options match all the conditions passed in. When passed a lambda, the
    #   lambda will execute with two arguments: the object being represented and the
    #   options passed into the representation call. Return true if you want the attribute
    #   to be exposed.
    # @option options :unless When passed a Hash, the attribute will be exposed if the
    #   runtime options fail to match any of the conditions passed in. If passed a lambda,
    #   it will yield the object being represented and the options passed to the
    #   representation call. Return true to prevent exposure, false to allow it.
    # @option options :using This option allows you to map an attribute to another Grape
    #   Entity. Pass it a Grape::Entity class and the attribute in question will
    #   automatically be transformed into a representation that will receive the same
    #   options as the parent entity when called. Note that arrays are fine here and
    #   will automatically be detected and handled appropriately.
    # @option options :proc If you pass a Proc into this option, it will
    #   be used directly to determine the value for that attribute. It
    #   will be called with the represented object as well as the
    #   runtime options that were passed in. You can also just supply a
    #   block to the expose call to achieve the same effect.
    # @option options :documentation Define documenation for an exposed
    #   field, typically the value is a hash with two fields, type and desc.
    def self.expose(*args, &block)
      options = merge_options(args.last.is_a?(Hash) ? args.pop : {})

      if args.size > 1
        raise ArgumentError, "You may not use the :as option on multi-attribute exposures." if options[:as]
        raise ArgumentError, "You may not use block-setting on multi-attribute exposures." if block_given?
      end

      raise ArgumentError, "You may not use block-setting when also using format_with" if block_given? && options[:format_with].respond_to?(:call)

      options[:proc] = block if block_given? && block.parameters.any?

      @nested_attributes ||= []

      args.each do |attribute|
        unless @nested_attributes.empty?
          attribute = "#{@nested_attributes.last}__#{attribute}"
          options[:nested] = true
          nested_exposures_hash[@nested_attributes.last.to_sym] ||= {}
          nested_exposures_hash[@nested_attributes.last.to_sym][attribute.to_sym] = options
        end

        exposures[attribute.to_sym] = options

        # Nested exposures are given in a block with no parameters.
        if block_given? && block.parameters.empty?
          @nested_attributes << attribute
          block.call
          @nested_attributes.pop
        end
      end
    end

    # Set options that will be applied to any exposures declared inside the block.
    #
    # @example Multi-exposure if
    #
    #   class MyEntity < Grape::Entity
    #     with_options if: { awesome: true } do
    #       expose :awesome, :sweet
    #     end
    #   end
    def self.with_options(options)
      (@block_options ||= []).push(valid_options(options))
      yield
      @block_options.pop
    end

    # Returns a hash of exposures that have been declared for this Entity or ancestors. The keys
    # are symbolized references to methods on the containing object, the values are
    # the options that were passed into expose.
    def self.exposures
      @exposures ||= {}

      if superclass.respond_to? :exposures
        @exposures = superclass.exposures.merge(@exposures)
      end

      @exposures
    end

    class << self
      attr_accessor :_nested_exposures_hash

      def nested_exposures_hash
        self._nested_exposures_hash ||= {}
      end

      def nested_exposures
        value = nested_exposures_hash

        if superclass.respond_to? :nested_exposures
          value = superclass.nested_exposures.deep_merge(value)
        end

        value
      end
    end

    # Returns a hash, the keys are symbolized references to fields in the entity,
    # the values are document keys in the entity's documentation key. When calling
    # #docmentation, any exposure without a documentation key will be ignored.
    def self.documentation
      @documentation ||= exposures.inject({}) do |memo, (attribute, exposure_options)|
        unless exposure_options[:documentation].nil? || exposure_options[:documentation].empty?
          memo[key_for(attribute)] = exposure_options[:documentation]
        end
        memo
      end

      if superclass.respond_to? :documentation
        @documentation = superclass.documentation.merge(@documentation)
      end

      @documentation
    end

    # This allows you to declare a Proc in which exposures can be formatted with.
    # It take a block with an arity of 1 which is passed as the value of the exposed attribute.
    #
    # @param name [Symbol] the name of the formatter
    # @param block [Proc] the block that will interpret the exposed attribute
    #
    # @example Formatter declaration
    #
    #   module API
    #     module Entities
    #       class User < Grape::Entity
    #         format_with :timestamp do |date|
    #           date.strftime('%m/%d/%Y')
    #         end
    #
    #         expose :birthday, :last_signed_in, format_with: :timestamp
    #       end
    #     end
    #   end
    #
    # @example Formatters are available to all decendants
    #
    #   Grape::Entity.format_with :timestamp do |date|
    #     date.strftime('%m/%d/%Y')
    #   end
    #
    def self.format_with(name, &block)
      raise ArgumentError, "You must pass a block for formatters" unless block_given?
      formatters[name.to_sym] = block
    end

    # Returns a hash of all formatters that are registered for this and it's ancestors.
    def self.formatters
      @formatters ||= {}

      if superclass.respond_to? :formatters
        @formatters = superclass.formatters.merge(@formatters)
      end

      @formatters
    end

    # This allows you to set a root element name for your representation.
    #
    # @param plural   [String] the root key to use when representing
    #   a collection of objects. If missing or nil, no root key will be used
    #   when representing collections of objects.
    # @param singular [String] the root key to use when representing
    #   a single object. If missing or nil, no root key will be used when
    #   representing an individual object.
    #
    # @example Entity Definition
    #
    #   module API
    #     module Entities
    #       class User < Grape::Entity
    #         root 'users', 'user'
    #         expose :id
    #       end
    #     end
    #   end
    #
    # @example Usage in the API Layer
    #
    #   module API
    #     class Users < Grape::API
    #       version 'v2'
    #
    #       # this will render { "users" : [ { "id" : "1" }, { "id" : "2" } ] }
    #       get '/users' do
    #         @users = User.all
    #         present @users, with: API::Entities::User
    #       end
    #
    #       # this will render { "user" : { "id" : "1" } }
    #       get '/users/:id' do
    #         @user = User.find(params[:id])
    #         present @user, with: API::Entities::User
    #       end
    #     end
    #   end
    def self.root(plural, singular = nil)
      @collection_root = plural
      @root = singular
    end

    # This convenience method allows you to instantiate one or more entities by
    # passing either a singular or collection of objects. Each object will be
    # initialized with the same options. If an array of objects is passed in,
    # an array of entities will be returned. If a single object is passed in,
    # a single entity will be returned.
    #
    # @param objects [Object or Array] One or more objects to be represented.
    # @param options [Hash] Options that will be passed through to each entity
    #   representation.
    #
    # @option options :root [String] override the default root name set for the entity.
    #   Pass nil or false to represent the object or objects with no root name
    #   even if one is defined for the entity.
    def self.represent(objects, options = {})
      if objects.respond_to?(:to_ary)
        inner = objects.to_ary.map { |object| new(object, { collection: true }.merge(options)) }
        inner = inner.map(&:serializable_hash) if options[:serializable]
      else
        inner = new(objects, options)
        inner = inner.serializable_hash if options[:serializable]
      end

      root_element = if options.has_key?(:root)
                       options[:root]
                     else
                       objects.respond_to?(:to_ary) ? @collection_root : @root
                     end

      root_element ? { root_element => inner } : inner
    end

    def initialize(object, options = {})
      @object, @options = object, options
    end

    def exposures
      self.class.exposures
    end

    def valid_exposures
      exposures.reject { |a, options| options[:nested] }.select do |attribute, exposure_options|
        valid_exposure?(attribute, exposure_options)
      end
    end

    def documentation
      self.class.documentation
    end

    def formatters
      self.class.formatters
    end

    # The serializable hash is the Entity's primary output. It is the transformed
    # hash for the given data model and is used as the basis for serialization to
    # JSON and other formats.
    #
    # @param runtime_options [Hash] Any options you pass in here will be known to the entity
    #   representation, this is where you can trigger things from conditional options
    #   etc.
    def serializable_hash(runtime_options = {})
      return nil if object.nil?
      opts = options.merge(runtime_options || {})
      valid_exposures.inject({}) do |output, (attribute, exposure_options)|
        if conditions_met?(exposure_options, opts)
          partial_output = value_for(attribute, opts)
          output[self.class.key_for(attribute)] =
            if partial_output.respond_to? :serializable_hash
              partial_output.serializable_hash(runtime_options)
            elsif partial_output.kind_of?(Array) && !partial_output.map { |o| o.respond_to? :serializable_hash }.include?(false)
              partial_output.map { |o| o.serializable_hash }
            elsif partial_output.kind_of?(Hash)
              partial_output.each do |key, value|
                partial_output[key] = value.serializable_hash if value.respond_to? :serializable_hash
              end
            else
              partial_output
            end
        end
        output
      end
    end

    alias_method :as_json, :serializable_hash

    def to_json(options = {})
      options = options.to_h if options && options.respond_to?(:to_h)
      MultiJson.dump(serializable_hash(options))
    end

    def to_xml(options = {})
      options = options.to_h if options && options.respond_to?(:to_h)
      serializable_hash(options).to_xml(options)
    end

    protected

    def self.name_for(attribute)
      attribute.to_s.split('__').last.to_sym
    end

    def self.key_for(attribute)
      exposures[attribute.to_sym][:as] || name_for(attribute)
    end

    def self.nested_exposures_for(attribute)
      nested_exposures[attribute] || {}
    end

    def value_for(attribute, options = {})
      exposure_options = exposures[attribute.to_sym]

      nested_exposures = self.class.nested_exposures_for(attribute)

      if exposure_options[:using]
        exposure_options[:using] = exposure_options[:using].constantize if exposure_options[:using].respond_to? :constantize

        using_options = options.dup
        using_options.delete(:collection)
        using_options[:root] = nil

        if exposure_options[:proc]
          exposure_options[:using].represent(instance_exec(object, options, &exposure_options[:proc]), using_options)
        else
          exposure_options[:using].represent(delegate_attribute(attribute), using_options)
        end

      elsif exposure_options[:proc]
        instance_exec(object, options, &exposure_options[:proc])

      elsif exposure_options[:format_with]
        format_with = exposure_options[:format_with]

        if format_with.is_a?(Symbol) && formatters[format_with]
          instance_exec(delegate_attribute(attribute), &formatters[format_with])
        elsif format_with.is_a?(Symbol)
          send(format_with, delegate_attribute(attribute))
        elsif format_with.respond_to? :call
          instance_exec(delegate_attribute(attribute), &format_with)
        end

      elsif nested_exposures.any?
        Hash[nested_exposures.map do |nested_attribute, _|
          [self.class.key_for(nested_attribute), value_for(nested_attribute, options)]
        end]

      else
        delegate_attribute(attribute)
      end
    end

    def delegate_attribute(attribute)
      name = self.class.name_for(attribute)
      if respond_to?(name, true)
        send(name)
      else
        object.send(name)
      end
    end

    def valid_exposure?(attribute, exposure_options)
      nested_exposures = self.class.nested_exposures_for(attribute)
      (nested_exposures.any? && nested_exposures.all? { |a, o| valid_exposure?(a, o) }) || \
      exposure_options.has_key?(:proc) || \
      !exposure_options[:safe] || \
      object.respond_to?(self.class.name_for(attribute))
    end

    def conditions_met?(exposure_options, options)
      if_conditions = (exposure_options[:if_extras] || []).dup
      if_conditions << exposure_options[:if] unless exposure_options[:if].nil?

      if_conditions.each do |if_condition|
        case if_condition
        when Hash then if_condition.each_pair { |k, v| return false if options[k.to_sym] != v }
        when Proc then return false unless instance_exec(object, options, &if_condition)
        when Symbol then return false unless options[if_condition]
        end
      end

      unless_conditions = (exposure_options[:unless_extras] || []).dup
      unless_conditions << exposure_options[:unless] unless exposure_options[:unless].nil?

      unless_conditions.each do |unless_condition|
        case unless_condition
        when Hash then unless_condition.each_pair { |k, v| return false if options[k.to_sym] == v }
        when Proc then return false if instance_exec(object, options, &unless_condition)
        when Symbol then return false if options[unless_condition]
        end
      end

      true
    end

    private

    # All supported options.
    OPTIONS = [
      :as, :if, :unless, :using, :with, :proc, :documentation, :format_with, :safe, :if_extras, :unless_extras
    ].to_set.freeze

    # Merges the given options with current block options.
    #
    # @param options [Hash] Exposure options.
    def self.merge_options(options)
      opts = {}

      merge_logic = proc do |key, existing_val, new_val|
        if [:if, :unless].include?(key)
          if existing_val.is_a?(Hash) && new_val.is_a?(Hash)
            existing_val.merge(new_val)
          elsif new_val.is_a?(Hash)
            (opts["#{key}_extras".to_sym] ||= []) << existing_val
            new_val
          else
            (opts["#{key}_extras".to_sym] ||= []) << new_val
            existing_val
          end
        else
          new_val
        end
      end

      @block_options ||= []
      opts.merge @block_options.inject({}) { |final, step|
        final.merge(step, &merge_logic)
      }.merge(valid_options(options), &merge_logic)
    end

    # Raises an error if the given options include unknown keys.
    # Renames aliased options.
    #
    # @param options [Hash] Exposure options.
    def self.valid_options(options)
      options.keys.each do |key|
        raise ArgumentError, "#{key.inspect} is not a valid option." unless OPTIONS.include?(key)
      end

      options[:using] = options.delete(:with) if options.has_key?(:with)
      options
    end
  end
end
