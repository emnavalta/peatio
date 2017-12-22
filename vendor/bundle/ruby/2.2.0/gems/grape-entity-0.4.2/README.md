# Grape::Entity

[![Build Status](https://travis-ci.org/agileanimal/grape-entity.png?branch=master)](https://travis-ci.org/agileanimal/grape-entity)

## Introduction

This gem adds Entity support to API frameworks, such as [Grape](https://github.com/intridea/grape). Grape's Entity is an API focused facade that sits on top of an object model.

### Example

```ruby
module API
  module Entities
    class Status < Grape::Entity
      format_with(:iso_timestamp) { |dt| dt.iso8601 }

      expose :user_name
      expose :text, documentation: { type: "String", desc: "Status update text." }
      expose :ip, if: { type: :full }
      expose :user_type, :user_id, if: lambda { |status, options| status.user.public? }
      expose :contact_info do
        expose :phone
        expose :address, using: API::Address
      end
      expose :digest do |status, options|
        Digest::MD5.hexdigest status.txt
      end
      expose :replies, using: API::Status, as: :replies
      expose :last_reply, using: API::Status do |status, options|
        status.replies.last
      end

      with_options(format_with: :iso_timestamp) do
        expose :created_at
        expose :updated_at
      end
    end
  end
end

module API
  module Entities
    class StatusDetailed < API::Entities::Status
      expose :internal_id
    end
  end
end
```

## Reusable Responses with Entities

Entities are a reusable means for converting Ruby objects to API responses. Entities can be used to conditionally include fields, nest other entities, and build ever larger responses, using inheritance.

### Defining Entities

Entities inherit from Grape::Entity, and define a simple DSL. Exposures can use runtime options to determine which fields should be visible, these options are available to `:if`, `:unless`, and `:proc`.

#### Basic Exposure

Define a list of fields that will always be exposed.

```ruby
expose :user_name, :ip
```

#### Exposing with a Presenter

Don't derive your model classes from `Grape::Entity`, expose them using a presenter.

```ruby
expose :replies, using: API::Status, as: :replies
```

Presenter classes can also be specified in string format, which helps with circular dependencies.

```ruby
expose :replies, using: `API::Status`, as: :replies
```

#### Conditional Exposure

Use `:if` or `:unless` to expose fields conditionally.

```ruby
expose :ip, if: { type: :full }

expose :ip, if: lambda { |instance, options| options[:type] == :full } # exposed if the function evaluates to true
expose :ip, if: :type # exposed if :type is available in the options hash
expose :ip, if { type: :full } # exposed if options :type has a value of :full

expose :ip, unless: ... # the opposite of :if
```

#### Safe Exposure

Don't raise an exception and expose as nil, even if the :x cannot be evaluated.

```ruby
expose :ip, safe: true
```

#### Nested Exposure

Supply a block to define a hash using nested exposures.

```ruby
expose :contact_info do
  expose :phone
  expose :address, using: API::Address
end
```

#### Runtime Exposure

Use a block or a `Proc` to evaluate exposure at runtime. The supplied block or
`Proc` will be called with two parameters: the represented object and runtime options.

**NOTE:** A block supplied with no parameters will be evaluated as a nested exposure (see above).

```ruby
expose :digest do |status, options|
  Digest::MD5.hexdigest status.txt
end
```

```ruby
expose :digest, proc: ... # equivalent to a block
```

You can also define a method on the entity and it will try that before trying
on the object the entity wraps.

```ruby
class ExampleEntity < Grape::Entity
  expose :attr_not_on_wrapped_object
  # ...
private

  def attr_not_on_wrapped_object
    42
  end
end
```

#### Aliases

Expose under a different name with `:as`.

```ruby
expose :replies, using: API::Status, as: :replies
```

#### Format Before Exposing

Apply a formatter before exposing a value.

```ruby
format_with(:iso_timestamp) { |dt| dt.iso8601 }
with_options(format_with: :iso_timestamp) do
  expose :created_at
  expose :updated_at
end
```

#### Documentation

Expose documentation with the field. Gets bubbled up when used with Grape and various API documentation systems.

```ruby
expose :text, documentation: { type: "String", desc: "Status update text." }
```

### Options Hash

The option keys `:version` and `:collection` are always defined. The `:version` key is defined as `api.version`. The `:collection` key is boolean, and defined as `true` if the object presented is an array. The options also contain the runtime environment in `:env`, which includes request parameters in `options[:env][:grape.request.params]`.

Any additional options defined on the entity exposure are included as is. In the following example `user` is set to the value of `current_user`.

```ruby
class Status < Grape::Entity
  expose :user, if: lambda { |instance, options| options[:user] } do |instance, options|
    # examine available environment keys with `p options[:env].keys`
    options[:user]
  end
end
```

```
present s, with: Status, user: current_user
```

### Using the Exposure DSL

Grape ships with a DSL to easily define entities within the context of an existing class:

```ruby
class Status
  include Grape::Entity::DSL

  entity :text, :user_id do
    expose :detailed, if: :conditional
  end
end
```

The above will automatically create a `Status::Entity` class and define properties on it according to the same rules as above. If you only want to define simple exposures you don't have to supply a block and can instead simply supply a list of comma-separated symbols.

### Using Entities

With Grape, once an entity is defined, it can be used within endpoints, by calling `present`. The `present` method accepts two arguments, the object to be presented and the options associated with it. The options hash must always include `:with`, which defines the entity to expose.

If the entity includes documentation it can be included in an endpoint's description.

```ruby
module API
  class Statuses < Grape::API
    version 'v1'

    desc 'Statuses.', {
      params: API::Entities::Status.documentation
    }
    get '/statuses' do
      statuses = Status.all
      type = current_user.admin? ? :full : :default
      present statuses, with: API::Entities::Status, type: type
    end
  end
end
```

### Entity Organization

In addition to separately organizing entities, it may be useful to put them as namespaced classes underneath the model they represent.

```ruby
class Status
  def entity
    Entity.new(self)
  end

  class Entity < Grape::Entity
    expose :text, :user_id
  end
end
```

If you organize your entities this way, Grape will automatically detect the `Entity` class and use it to present your models. In this example, if you added `present User.new` to your endpoint, Grape would automatically detect that there is a `Status::Entity` class and use that as the representative entity. This can still be overridden by using the `:with` option or an explicit `represents` call.

### Caveats

Entities with duplicate exposure names and conditions will silently overwrite one another. In the following example, when `object.check` equals "foo", only `field_a` will be exposed. However, when `object.check` equals "bar" both `field_b` and `foo` will be exposed.

```ruby
module API
  module Entities
    class Status < Grape::Entity
      expose :field_a, :foo, if: lambda { |object, options| object.check == "foo" }
      expose :field_b, :foo, if: lambda { |object, options| object.check == "bar" }
    end
  end
end
```

This can be problematic, when you have mixed collections. Using `respond_to?` is safer.

```ruby
module API
  module Entities
    class Status < Grape::Entity
      expose :field_a, if: lambda { |object, options| object.check == "foo" }
      expose :field_b, if: lambda { |object, options| object.check == "bar" }
      expose :foo, if: lambda { |object, options| object.respond_to?(:foo) }
    end
  end
end
```

Also note that an `ArgumentError` is raised when unknown options are passed to either `expose` or `with_options`.

## Installation

Add this line to your application's Gemfile:

    gem 'grape-entity'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install grape-entity

## Testing with Entities

Test API request/response as usual.

Also see [Grape Entity Matchers](https://github.com/agileanimal/grape-entity-matchers).

## Project Resources

* Need help? [Grape Google Group](http://groups.google.com/group/ruby-grape)

## Contributing

1. Fork the project
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Write tests. Make changes. Run `rubocop`.
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new pull request

## License

MIT License. See LICENSE for details.

## Copyright

Copyright (c) 2010-2013 Michael Bleigh, Intridea, Inc., and contributors.

