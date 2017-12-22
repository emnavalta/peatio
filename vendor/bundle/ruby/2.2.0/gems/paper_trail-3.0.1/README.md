# PaperTrail [![Build Status](https://img.shields.io/travis/airblade/paper_trail/master.svg)](https://travis-ci.org/airblade/paper_trail) [![Dependency Status](https://img.shields.io/gemnasium/airblade/paper_trail.svg)](https://gemnasium.com/airblade/paper_trail)

PaperTrail lets you track changes to your models' data.  It's good for auditing or versioning.  You can see how a model looked at any stage in its lifecycle, revert it to any version, and even undelete it after it's been destroyed.

There's an excellent [RailsCast on implementing Undo with Paper Trail](http://railscasts.com/episodes/255-undo-with-paper-trail).

## Features

* Stores every create, update and destroy (or only the lifecycle events you specify).
* Does not store updates which don't change anything.
* Allows you to specify attributes (by inclusion or exclusion) which must change for a Version to be stored.
* Allows you to get at every version, including the original, even once destroyed.
* Allows you to get at every version even if the schema has since changed.
* Allows you to get at the version as of a particular time.
* Option to automatically restore `has_one` associations as they were at the time.
* Automatically records who was responsible via your controller.  PaperTrail calls `current_user` by default, if it exists, but you can have it call any method you like.
* Allows you to set who is responsible at model-level (useful for migrations).
* Allows you to store arbitrary model-level metadata with each version (useful for filtering versions).
* Allows you to store arbitrary controller-level information with each version, e.g. remote IP.
* Can be turned off/on per class (useful for migrations).
* Can be turned off/on per request (useful for testing with an external service).
* Can be turned off/on globally (useful for testing).
* No configuration necessary.
* Stores everything in a single database table by default (generates migration for you), or can use separate tables for separate models.
* Supports custom version classes so different models' versions can have different behaviour.
* Supports custom name for versions association.
* Thoroughly tested.
* Threadsafe.


## Compatibility

Works with ActiveRecord 4 and ActiveRecord 3. Note: this code is on the `master` branch and tagged `v3.x`.

Version 2 is on the branch named [`2.7-stable`](https://github.com/airblade/paper_trail/tree/2.7-stable) and is tagged `v2.x`, and works with Rails 3.

The Rails 2.3 code is on the [`rails2`](https://github.com/airblade/paper_trail/tree/rails2) branch and tagged `v1.x`. These branches are both stable with their respective versions of Rails but will not have new features added/backported to them.

## Installation

### Rails 3 & 4

1. Add `PaperTrail` to your `Gemfile`.

    `gem 'paper_trail', '~> 3.0.1'`

2. Generate a migration which will add a `versions` table to your database.

    `bundle exec rails generate paper_trail:install`

3. Run the migration.

    `bundle exec rake db:migrate`

4. Add `has_paper_trail` to the models you want to track.

### Sinatra

In order to configure `PaperTrail` for usage with [Sinatra](http://www.sinatrarb.com),
your `Sinatra` app must be using `ActiveRecord` 3 or  `ActiveRecord` 4. It is also recommended to use the
[Sinatra ActiveRecord Extension](https://github.com/janko-m/sinatra-activerecord) or something similar for managing
your applications `ActiveRecord` connection in a manner similar to the way `Rails` does. If using the aforementioned
`Sinatra ActiveRecord Extension`, steps for setting up your app with `PaperTrail` will look something like this:

1. Add `PaperTrail` to your `Gemfile`.

    `gem 'paper_trail', '~> 3.0.1'`

2. Generate a migration to add a `versions` table to your database.

    `bundle exec rake db:create_migration NAME=create_versions`

3. Copy contents of [create_versions.rb](https://raw.github.com/airblade/paper_trail/master/lib/generators/paper_trail/templates/create_versions.rb)
into the `create_versions` migration that was generated into your `db/migrate` directory.

4. Run the migration.

    `bundle exec rake db:migrate`

5. Add `has_paper_trail` to the models you want to track.


PaperTrail provides a helper extension that acts similar to the controller mixin it provides for `Rails` applications.

It will set `PaperTrail.whodunnit` to whatever is returned by a method named `user_for_paper_trail` which you can define inside your Sinatra Application. (by default it attempts to invoke a method named `current_user`)

If you're using the modular [`Sinatra::Base`](http://www.sinatrarb.com/intro.html#Modular%20vs.%20Classic%20Style) style of application, you will need to register the extension:

```ruby
# bleh_app.rb
require 'sinatra/base'

class BlehApp < Sinatra::Base
  register PaperTrail::Sinatra
end
```

## API Summary

When you declare `has_paper_trail` in your model, you get these methods:

```ruby
class Widget < ActiveRecord::Base
  has_paper_trail   # you can pass various options here
end

# Returns this widget's versions.  You can customise the name of the association.
widget.versions

# Return the version this widget was reified from, or nil if it is live.
# You can customise the name of the method.
widget.version

# Returns true if this widget is the current, live one; or false if it is from a previous version.
widget.live?

# Returns who put the widget into its current state.
widget.originator

# Returns the widget (not a version) as it looked at the given timestamp.
widget.version_at(timestamp)

# Returns the widget (not a version) as it was most recently.
widget.previous_version

# Returns the widget (not a version) as it became next.
widget.next_version

# Generates a version for a `touch` event (`widget.touch` does NOT generate a version)
widget.touch_with_version

# Turn PaperTrail off for all widgets.
Widget.paper_trail_off!

# Turn PaperTrail on for all widgets.
Widget.paper_trail_on!

# Check wheter PaperTrail is enabled for all widgets
Widget.paper_trail_enabled_for_model?
widget.paper_trail_enabled_for_model?
```

And a `PaperTrail::Version` instance has these methods:

```ruby
# Returns the item restored from this version.
version.reify(options = {})

# Returns who put the item into the state stored in this version.
version.originator

# Returns who changed the item from the state it had in this version.
version.terminator
version.whodunnit
version.version_author

# Returns the next version.
version.next

# Returns the previous version.
version.previous

# Returns the index of this version in all the versions.
version.index

# Returns the event that caused this version (create|update|destroy).
version.event
```

In your controllers you can override these methods:

```ruby
# Returns the user who is responsible for any changes that occur.
# Defaults to current_user.
user_for_paper_trail

# Returns any information about the controller or request that you want
# PaperTrail to store alongside any changes that occur.
info_for_paper_trail
```

## Basic Usage

PaperTrail is simple to use.  Just add 15 characters to a model to get a paper trail of every `create`, `update`, and `destroy`.

```ruby
class Widget < ActiveRecord::Base
  has_paper_trail
end
```

This gives you a `versions` method which returns the paper trail of changes to your model.

```ruby
>> widget = Widget.find 42
>> widget.versions             # [<PaperTrail::Version>, <PaperTrail::Version>, ...]
```

Once you have a version, you can find out what happened:

```ruby
>> v = widget.versions.last
>> v.event                     # 'update' (or 'create' or 'destroy')
>> v.whodunnit                 # '153'  (if the update was via a controller and
                               #         the controller has a current_user method,
                               #         here returning the id of the current user)
>> v.created_at                # when the update occurred
>> widget = v.reify            # the widget as it was before the update;
                               # would be nil for a create event
```

PaperTrail stores the pre-change version of the model, unlike some other auditing/versioning plugins, so you can retrieve the original version.  This is useful when you start keeping a paper trail for models that already have records in the database.

```ruby
>> widget = Widget.find 153
>> widget.name                                 # 'Doobly'

# Add has_paper_trail to Widget model.

>> widget.versions                             # []
>> widget.update_attributes :name => 'Wotsit'
>> widget.versions.last.reify.name             # 'Doobly'
>> widget.versions.last.event                  # 'update'
```

This also means that PaperTrail does not waste space storing a version of the object as it currently stands.  The `versions` method gives you previous versions; to get the current one just call a finder on your `Widget` model as usual.

Here's a helpful table showing what PaperTrail stores:

<table>
  <tr>
    <th>Event</th>
    <th>Model Before</th>
    <th>Model After</th>
  </tr>
  <tr>
    <td>create</td>
    <td>nil</td>
    <td>widget</td>
  </tr>
  <tr>
    <td>update</td>
    <td>widget</td>
    <td>widget'</td>
  <tr>
    <td>destroy</td>
    <td>widget</td>
    <td>nil</td>
  </tr>
</table>

PaperTrail stores the values in the Model Before column.  Most other auditing/versioning plugins store the After column.


## Choosing Lifecycle Events To Monitor

You can choose which events to track with the `on` option.  For example, to ignore `create` events:

```ruby
class Article < ActiveRecord::Base
  has_paper_trail :on => [:update, :destroy]
end
```

You may also have the `PaperTrail::Version` model save a custom string in it's `event` field instead of the typical `create`, `update`, `destroy`.
PaperTrail supplies a custom accessor method called `paper_trail_event`, which it will attempt to use to fill the `event` field before
falling back on one of the default events.

```ruby
>> a = Article.create
>> a.versions.size                           # 1
>> a.versions.last.event                     # 'create'
>> a.paper_trail_event = 'update title'
>> a.update_attributes :title => 'My Title'
>> a.versions.size                           # 2
>> a.versions.last.event                     # 'update title'
>> a.paper_trail_event = nil
>> a.update_attributes :title => "Alternate"
>> a.versions.size                           # 3
>> a.versions.last.event                     # 'update'
```

## Choosing When To Save New Versions

You can choose the conditions when to add new versions with the `if` and `unless` options. For example, to save versions only for US non-draft translations:

```ruby
class Translation < ActiveRecord::Base
  has_paper_trail :if     => Proc.new { |t| t.language_code == 'US' },
                  :unless => Proc.new { |t| t.type == 'DRAFT'       }
end
```


## Choosing Attributes To Monitor

You can ignore changes to certain attributes like this:

```ruby
class Article < ActiveRecord::Base
  has_paper_trail :ignore => [:title, :rating]
end
```

This means that changes to just the `title` or `rating` will not store another version of the article.  It does not mean that the `title` and `rating` attributes will be ignored if some other change causes a new `PaperTrail::Version` to be created.  For example:

```ruby
>> a = Article.create
>> a.versions.length                         # 1
>> a.update_attributes :title => 'My Title', :rating => 3
>> a.versions.length                         # 1
>> a.update_attributes :title => 'Greeting', :content => 'Hello'
>> a.versions.length                         # 2
>> a.previous_version.title                  # 'My Title'
```

Or, you can specify a list of all attributes you care about:

```ruby
class Article < ActiveRecord::Base
  has_paper_trail :only => [:title]
end
```

This means that only changes to the `title` will save a version of the article:

```ruby
>> a = Article.create
>> a.versions.length                         # 1
>> a.update_attributes :title => 'My Title'
>> a.versions.length                         # 2
>> a.update_attributes :content => 'Hello'
>> a.versions.length                         # 2
>> a.previous_version.content                # nil
```

The `:ignore` and `:only` options can also accept `Hash` arguments, where the :

```ruby
class Article < ActiveRecord::Base
  has_paper_trail :only => [:title => Proc.new { |obj| !obj.title.blank? } ]
end
```

This means that if the `title` is not blank, then only changes to the `title` will save a version of the article:

```ruby
>> a = Article.create
>> a.versions.length                         # 1
>> a.update_attributes :content => 'Hello'
>> a.versions.length                         # 2
>> a.update_attributes :title => 'My Title'
>> a.versions.length                         # 3
>> a.update_attributes :content => 'Hai'
>> a.versions.length                         # 3
>> a.previous_version.content                # "Hello"
>> a.update_attributes :title => 'Dif Title'
>> a.versions.length                         # 4
>> a.previous_version.content                # "Hai"
```

Passing both `:ignore` and `:only` options will result in the article being saved if a changed attribute is included in `:only` but not in `:ignore`.

You can skip fields altogether with the `:skip` option.  As with `:ignore`, updates to these fields will not create a new `PaperTrail::Version`.  In addition, these fields will not be included in the serialized version of the object whenever a new `PaperTrail::Version` is created.

For example:

```ruby
class Article < ActiveRecord::Base
  has_paper_trail :skip => [:file_upload]
end
```

## Reverting And Undeleting A Model

PaperTrail makes reverting to a previous version easy:

```ruby
>> widget = Widget.find 42
>> widget.update_attributes :name => 'Blah blah'
# Time passes....
>> widget = widget.previous_version  # the widget as it was before the update
>> widget.save                       # reverted
```

Alternatively you can find the version at a given time:

```ruby
>> widget = widget.version_at(1.day.ago)  # the widget as it was one day ago
>> widget.save                            # reverted
```

Note `version_at` gives you the object, not a version, so you don't need to call `reify`.

Undeleting is just as simple:

```ruby
>> widget = Widget.find 42
>> widget.destroy
# Time passes....
>> widget = PaperTrail::Version.find(153).reify  # the widget as it was before destruction
>> widget.save                         # the widget lives!
```

In fact you could use PaperTrail to implement an undo system, though I haven't had the opportunity yet to do it myself.  However [Ryan Bates has](http://railscasts.com/episodes/255-undo-with-paper-trail)!


## Navigating Versions

You can call `previous_version` and `next_version` on an item to get it as it was/became.  Note that these methods reify the item for you.

```ruby
>> live_widget = Widget.find 42
>> live_widget.versions.length           # 4 for example
>> widget = live_widget.previous_version # => widget == live_widget.versions.last.reify
>> widget = widget.previous_version      # => widget == live_widget.versions[-2].reify
>> widget = widget.next_version          # => widget == live_widget.versions.last.reify
>> widget.next_version                   # live_widget
```

If instead you have a particular `version` of an item you can navigate to the previous and next versions.

```ruby
>> widget = Widget.find 42
>> version = widget.versions[-2]    # assuming widget has several versions
>> previous = version.previous
>> next = version.next
```

You can find out which of an item's versions yours is:

```ruby
>> current_version_number = version.index    # 0-based
```

Finally, if you got an item by reifying one of its versions, you can navigate back to the version it came from:

```ruby
>> latest_version = Widget.find(42).versions.last
>> widget = latest_version.reify
>> widget.version == latest_version    # true
```

You can find out whether a model instance is the current, live one -- or whether it came instead from a previous version -- with `live?`:

```ruby
>> widget = Widget.find 42
>> widget.live?                        # true
>> widget = widget.previous_version
>> widget.live?                        # false
```

## Finding Out Who Was Responsible For A Change

If your `ApplicationController` has a `current_user` method, PaperTrail will store the value it returns in the version's `whodunnit` column.  Note that this column is of type `String`, so you will have to convert it to an integer if it's an id and you want to look up the user later on:

```ruby
>> last_change = widget.versions.last
>> user_who_made_the_change = User.find last_change.whodunnit.to_i
```

You may want PaperTrail to call a different method to find out who is responsible.  To do so, override the `user_for_paper_trail` method in your controller like this:

```ruby
class ApplicationController
  def user_for_paper_trail
    logged_in? ? current_member.id : 'Public user'  # or whatever
  end
end
```

In a console session you can manually set who is responsible like this:

```ruby
>> PaperTrail.whodunnit = 'Andy Stewart'
>> widget.update_attributes :name => 'Wibble'
>> widget.versions.last.whodunnit              # Andy Stewart
```

You can avoid having to do this manually by setting your initializer to pick up the username of the current user from the OS, like this:

```ruby
# config/initializers/paper_trail.rb
if defined?(::Rails::Console)
  PaperTrail.whodunnit = "#{`whoami`.strip}: console"
elsif File.basename($0) == "rake"
  PaperTrail.whodunnit = "#{`whoami`.strip}: rake #{ARGV.join ' '}"
end
```

Sometimes you want to define who is responsible for a change in a small scope without overwriting value of `PaperTrail.whodunnit`. It is possible to define the `whodunnit` value for an operation inside a block like this:

```ruby
>> PaperTrail.whodunnit = 'Andy Stewart'
>> widget.whodunnit('Lucas Souza') do
>>   widget.update_attributes :name => 'Wibble'
>> end
>> widget.versions.last.whodunnit              # Lucas Souza
>> widget.update_attributes :name => 'Clair'
>> widget.versions.last.whodunnit              # Andy Stewart
>> widget.whodunnit('Ben Atkins') { |w| w.update_attributes :name => 'Beth' } # this syntax also works
>> widget.versions.last.whodunnit              # Ben Atkins
```

A version's `whodunnit` records who changed the object causing the `version` to be stored.  Because a version stores the object as it looked before the change (see the table above), `whodunnit` returns who stopped the object looking like this -- not who made it look like this.  Hence `whodunnit` is aliased as `terminator`.

To find out who made a version's object look that way, use `version.originator`.  And to find out who made a "live" object look like it does, use `originator` on the object.

```ruby
>> widget = Widget.find 153                    # assume widget has 0 versions
>> PaperTrail.whodunnit = 'Alice'
>> widget.update_attributes :name => 'Yankee'
>> widget.originator                           # 'Alice'
>> PaperTrail.whodunnit = 'Bob'
>> widget.update_attributes :name => 'Zulu'
>> widget.originator                           # 'Bob'
>> first_version, last_version = widget.versions.first, widget.versions.last
>> first_version.whodunnit                     # 'Alice'
>> first_version.originator                    # nil
>> first_version.terminator                    # 'Alice'
>> last_version.whodunnit                      # 'Bob'
>> last_version.originator                     # 'Alice'
>> last_version.terminator                     # 'Bob'
```

## Custom Version Classes

You can specify custom version subclasses with the `:class_name` option:

```ruby
class PostVersion < PaperTrail::Version
  # custom behaviour, e.g:
  self.table_name = :post_versions
end

class Post < ActiveRecord::Base
  has_paper_trail :class_name => 'PostVersion'
end
```

This allows you to store each model's versions in a separate table, which is useful if you have a lot of versions being created.

If you are using Postgres, you should also define the sequence that your custom version class will use:

```ruby
class PostVersion < PaperTrail::Version
  self.table_name = :post_versions
  self.sequence_name = :post_version_id_seq
end
```

Alternatively you could store certain metadata for one type of version, and other metadata for other versions.

If you only use custom version classes and don't use PaperTrail's built-in one, on Rails `>= 3.2` you must:

- either declare the `PaperTrail::Version` class to be abstract like this (in an initializer):

```ruby
PaperTrail::Version.module_eval do
  self.abstract_class = true
end
```

- or create a `versions` table in the database so Rails can instantiate the `PaperTrail::Version` superclass.

You can also specify custom names for the versions and version associations.  This is useful if you already have `versions` or/and `version` methods on your model.  For example:

```ruby
class Post < ActiveRecord::Base
  has_paper_trail :versions => :paper_trail_versions,
                  :version  => :paper_trail_version

  # Existing versions method.  We don't want to clash.
  def versions
    ...
  end
  # Existing version method.  We don't want to clash.
  def version
    ...
  end
end
```

## Associations

I haven't yet found a good way to get PaperTrail to automatically restore associations when you reify a model.  See [here for a little more info](http://airbladesoftware.com/notes/undo-and-redo-with-papertrail).

If you can think of a good way to achieve this, please let me know.


## Has-One Associations

PaperTrail can restore `:has_one` associations as they were at (actually, 3 seconds before) the time.

```ruby
class Location < ActiveRecord::Base
  belongs_to :treasure
  has_paper_trail
end

class Treasure < ActiveRecord::Base
  has_one :location
  has_paper_trail
end

>> treasure.amount                  # 100
>> treasure.location.latitude       # 12.345

>> treasure.update_attributes :amount => 153
>> treasure.location.update_attributes :latitude => 54.321

>> t = treasure.versions.last.reify(:has_one => true)
>> t.amount                         # 100
>> t.location.latitude              # 12.345
```

The implementation is complicated by the edge case where the parent and child are updated in one go, e.g. in one web request or database transaction.  PaperTrail doesn't know about different models being updated "together", so you can't ask it definitively to get the child as it was before the joint parent-and-child update.

The correct solution is to make PaperTrail aware of requests or transactions (c.f. [Efficiency's transaction ID middleware](http://github.com/efficiency20/ops_middleware/blob/master/lib/e20/ops/middleware/transaction_id_middleware.rb)).  In the meantime we work around the problem by finding the child as it was a few seconds before the parent was updated.  By default we go 3 seconds before but you can change this by passing the desired number of seconds to the `:has_one` option:

```ruby
>> t = treasure.versions.last.reify(:has_one => 1)  # look back 1 second instead of 3
```

If you are shuddering, take solace from knowing PaperTrail opts out of these shenanigans by default. This means your `:has_one` associated objects will be the live ones, not the ones the user saw at the time.  Since PaperTrail doesn't auto-restore `:has_many` associations (I can't get it to work) or `:belongs_to` (I ran out of time looking at `:has_many`), this at least makes your associations wrong consistently ;)



## Has-Many-Through Associations

PaperTrail can track most changes to the join table.  Specifically it can track all additions but it can only track removals which fire the `after_destroy` callback on the join table.  Here are some examples:

Given these models:

```ruby
class Book < ActiveRecord::Base
  has_many :authorships, :dependent => :destroy
  has_many :authors, :through => :authorships, :source => :person
  has_paper_trail
end

class Authorship < ActiveRecord::Base
  belongs_to :book
  belongs_to :person
  has_paper_trail      # NOTE
end

class Person < ActiveRecord::Base
  has_many :authorships, :dependent => :destroy
  has_many :books, :through => :authorships
  has_paper_trail
end
```

Then each of the following will store authorship versions:

```ruby
>> @book.authors << @dostoyevsky
>> @book.authors.create :name => 'Tolstoy'
>> @book.authorships.last.destroy
>> @book.authorships.clear
```

But none of these will:

```ruby
>> @book.authors.delete @tolstoy
>> @book.author_ids = [@solzhenistyn.id, @dostoyevsky.id]
>> @book.authors = []
```

Having said that, you can apparently get all these working (I haven't tested it myself) with this patch:

```ruby
# In config/initializers/active_record_patch.rb
module ActiveRecord
  # = Active Record Has Many Through Association
  module Associations
    class HasManyThroughAssociation < HasManyAssociation #:nodoc:
      alias_method :original_delete_records, :delete_records

      def delete_records(records, method)
        method ||= :destroy
        original_delete_records(records, method)
      end
    end
  end
end
```

See [issue 113](https://github.com/airblade/paper_trail/issues/113) for a discussion about this.

There may be a way to store authorship versions, probably using association callbacks, no matter how the collection is manipulated but I haven't found it yet.  Let me know if you do.

There has been some discussion of how to implement PaperTrail to fully track HABTM associations. See [pull 90](https://github.com/airblade/paper_trail/pull/90) for an implementation that has worked for some.

## Storing metadata

You can store arbitrary model-level metadata alongside each version like this:

```ruby
class Article < ActiveRecord::Base
  belongs_to :author
  has_paper_trail :meta => { :author_id  => :author_id,
                             :word_count => :count_words,
                             :answer     => 42 }
  def count_words
    153
  end
end
```

PaperTrail will call your proc with the current article and store the result in the `author_id` column of the `versions` table.

N.B.  You must also:

* Add your metadata columns to the `versions` table.
* Declare your metadata columns using `attr_accessible`. (If you are using `ActiveRecord 3`, or `ActiveRecord 4` with the [ProtectedAttributes](https://github.com/rails/protected_attributes) gem)

For example:

```ruby
# config/initializers/paper_trail.rb
module PaperTrail
  class Version < ActiveRecord::Base
    attr_accessible :author_id, :word_count, :answer
  end
end
```

Why would you do this?  In this example, `author_id` is an attribute of `Article` and PaperTrail will store it anyway in a serialized form in the `object` column of the `version` record.  But let's say you wanted to pull out all versions for a particular author; without the metadata you would have to deserialize (reify) each `version` object to see if belonged to the author in question.  Clearly this is inefficient.  Using the metadata you can find just those versions you want:

```ruby
PaperTrail::Version.where(:author_id => author_id)
```

Note you can pass a symbol as a value in the `meta` hash to signal a method to call.

You can also store any information you like from your controller.  Just override the `info_for_paper_trail` method in your controller to return a hash whose keys correspond to columns in your `versions` table.  E.g.:

```ruby
class ApplicationController
  def info_for_paper_trail
    { :ip => request.remote_ip, :user_agent => request.user_agent }
  end
end
```

Remember to add those extra columns to your `versions` table and use `attr_accessible` ;)

**NOTE FOR RAILS 4:** If you're using [Strong Parameters](https://github.com/rails/strong_parameters) in Rails 4 and have *not* included the `protected_attributes` gem, there's no need to declare your metadata columns using `attr_accessible`.


## Diffing Versions

There are two scenarios: diffing adjacent versions and diffing non-adjacent versions.

The best way to diff adjacent versions is to get PaperTrail to do it for you.  If you add an `object_changes` text column to your `versions` table, either at installation time with the `rails generate paper_trail:install --with-changes` option or manually, PaperTrail will store the `changes` diff (excluding any attributes PaperTrail is ignoring) in each `update` version.  You can use the `version.changeset` method to retrieve it.  For example:

```ruby
>> widget = Widget.create :name => 'Bob'
>> widget.versions.last.changeset                # {'name' => [nil, 'Bob']}
>> widget.update_attributes :name => 'Robert'
>> widget.versions.last.changeset                # {'name' => ['Bob', 'Robert']}
>> widget.destroy
>> widget.versions.last.changeset                # {}
```

Note PaperTrail only stores the changes for creation and updates; it doesn't store anything when an object is destroyed.

Please be aware that PaperTrail doesn't use diffs internally.  When I designed PaperTrail I wanted simplicity and robustness so I decided to make each version of an object self-contained.  A version stores all of its object's data, not a diff from the previous version.  This means you can delete any version without affecting any other.

To diff non-adjacent versions you'll have to write your own code.  These libraries may help:

For diffing two strings:

* [htmldiff](http://github.com/myobie/htmldiff): expects but doesn't require HTML input and produces HTML output.  Works very well but slows down significantly on large (e.g. 5,000 word) inputs.
* [differ](http://github.com/pvande/differ): expects plain text input and produces plain text/coloured/HTML/any output.  Can do character-wise, word-wise, line-wise, or arbitrary-boundary-string-wise diffs.  Works very well on non-HTML input.
* [diff-lcs](https://github.com/halostatue/diff-lcs): old-school, line-wise diffs.

For diffing two ActiveRecord objects:

* [Jeremy Weiskotten's PaperTrail fork](http://github.com/jeremyw/paper_trail/blob/master/lib/paper_trail/has_paper_trail.rb#L151-156): uses ActiveSupport's diff to return an array of hashes of the changes.
* [activerecord-diff](http://github.com/tim/activerecord-diff): rather like ActiveRecord::Dirty but also allows you to specify which columns to compare.


## Turning PaperTrail Off/On

Sometimes you don't want to store changes.  Perhaps you are only interested in changes made by your users and don't need to store changes you make yourself in, say, a migration -- or when testing your application.

You can turn PaperTrail on or off in three ways: globally, per request, or per class.

### Globally

On a global level you can turn PaperTrail off like this:

```ruby
>> PaperTrail.enabled = false
```

For example, you might want to disable PaperTrail in your Rails application's test environment to speed up your tests.  This will do it (note: this gets done automatically for `RSpec` and `Cucumber`, please see the [Testing section](#testing)):

```ruby
# in config/environments/test.rb
config.after_initialize do
  PaperTrail.enabled = false
end
```

If you disable PaperTrail in your test environment but want to enable it for specific tests, you can add a helper like this to your test helper:

```ruby
# in test/test_helper.rb
def with_versioning
  was_enabled = PaperTrail.enabled?
  PaperTrail.enabled = true
  begin
    yield
  ensure
    PaperTrail.enabled = was_enabled
  end
end
```

And then use it in your tests like this:

```ruby
test "something that needs versioning" do
  with_versioning do
    # your test
  end
end
```

### Per request

You can turn PaperTrail on or off per request by adding a `paper_trail_enabled_for_controller` method to your controller which returns `true` or `false`:

```ruby
class ApplicationController < ActionController::Base
  def paper_trail_enabled_for_controller
    request.user_agent != 'Disable User-Agent'
  end
end
```

### Per class

If you are about change some widgets and you don't want a paper trail of your changes, you can turn PaperTrail off like this:

```ruby
>> Widget.paper_trail_off!
```

And on again like this:

```ruby
>> Widget.paper_trail_on!
```

### Per method call

You can call a method without creating a new version using `without_versioning`.  It takes either a method name as a symbol:

```ruby
@widget.without_versioning :destroy
```

Or a block:

```ruby
@widget.without_versioning do
  @widget.update_attributes :name => 'Ford'
end
```

## Using a custom serializer

By default, PaperTrail stores your changes as a `YAML` dump. You can override this with the serializer config option:

```ruby
>> PaperTrail.serializer = MyCustomSerializer
```

A valid serializer is a `module` (or `class`) that defines a `load` and `dump` method.  These serializers are included in the gem for your convenience:

* [YAML](https://github.com/airblade/paper_trail/blob/master/lib/paper_trail/serializers/yaml.rb) - Default
* [JSON](https://github.com/airblade/paper_trail/blob/master/lib/paper_trail/serializers/json.rb)

## Limiting the number of versions created per object instance

If you are weary of your `versions` table growing to an unwieldy size, or just don't care to track more than a certain number of versions per object,
there is a configuration option that can be set to cap the number of versions saved per object. Note that this value must be numeric, and it only applies to
versions other than `create` events (which will always be preserved if they are stored).

```ruby
# will make it so that a maximum of 4 versions will be stored for each object
# (the 3 most recent ones plus a `create` event)
>> PaperTrail.config.version_limit = 3
# disables/removes the version limit
>> PaperTrail.config.version_limit = nil
```

## Deleting Old Versions

Over time your `versions` table will grow to an unwieldy size.  Because each version is self-contained (see the Diffing section above for more) you can simply delete any records you don't want any more.  For example:

```sql
sql> delete from versions where created_at < 2010-06-01;
```

```ruby
>> PaperTrail::Version.delete_all ["created_at < ?", 1.week.ago]
```

## Testing

You may want to turn PaperTrail off to speed up your tests.  See the [Turning PaperTrail Off/On](#turning-papertrail-offon) section above for tips on usage with `Test::Unit`.

### RSpec

PaperTrail provides a helper that works with [RSpec](https://github.com/rspec/rspec) to make it easier to control when `PaperTrail` is enabled
during testing. By default, PaperTrail will be turned off for all tests.
When you wish to enable PaperTrail for a test you can either wrap the test in a `with_versioning` block, or pass in `:versioning => true` option to a spec block, like so:

```ruby
describe "RSpec test group" do
  it 'by default, PaperTrail will be turned off' do
    PaperTrail.should_not be_enabled
  end

  with_versioning do
    it 'within a `with_versioning` block it will be turned on' do
      PaperTrail.should be_enabled
    end
  end

  it 'can be turned on at the `it` or `describe` level like this', :versioning => true do
    PaperTrail.should be_enabled
  end
end
```

The helper will also reset the `PaperTrail.whodunnit` value to `nil` before each test to help prevent data spillover between tests.
If you are using PaperTrail with Rails, the helper will automatically set the `PaperTrail.controller_info` value to `{}` as well, again, to help prevent data spillover between tests.

There is also a `be_versioned` matcher provided by PaperTrail's RSpec helper which can be leveraged like so:

```ruby
class Widget < ActiveRecord::Base
end

describe Widget do
  it { should_not be_versioned }

  describe "add versioning to the `Widget` class" do
    before(:all) do
      class Widget < ActiveRecord::Base
        has_paper_trail
      end
    end

    it { should be_versioned }
  end
end
```

### Cucumber

PaperTrail provides a helper for [Cucumber](http://cukes.info) that works similar to the RSpec helper.
By default, PaperTrail will be turned off for all scenarios by a `before` hook added by the helper.
When you wish to enable PaperTrail for a scenario, you can wrap code in a `with_versioning` block in a step, like so:

```ruby
Given /I want versioning on my model/ do
  with_versioning do
    # PaperTrail will be turned on for all code inside of this block
  end
end
```

The helper will also reset the `PaperTrail.whodunnit` value to `nil` before each test to help prevent data spillover between tests.
If you are using PaperTrail with Rails, the helper will automatically set the `PaperTrail.controller_info` value to `{}` as well, again, to help prevent data spillover between tests.

### Spork

If you wish to use the `RSpec` or `Cucumber` helpers with [Spork](https://github.com/sporkrb/spork), you will need to
manually require the helper(s) in your `prefork` block on your test helper, like so:

```ruby
# spec/spec_helper.rb

require 'spork'

Spork.prefork do
  # This file is copied to spec/ when you run 'rails generate rspec:install'
  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'
  require 'rspec/autorun'
  require 'paper_trail/frameworks/rspec'
  require 'paper_trail/frameworks/cucumber'
  ...
end
```

### Zeus

If you wish to use the `RSpec` or `Cucumber` heleprs with [Zeus](https://github.com/burke/zeus), you will need to
manually require the helper(s) in your test helper, like so:

```ruby
# spec/spec_helper.rb

ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'paper_trail/frameworks/rspec'
```

## Articles

[Using PaperTrail to track stack traces](http://rubyrailsexpert.com/?p=36), T James Corcoran's blog, 1st October 2013.
[RailsCast #255 - Undo with PaperTrail](http://railscasts.com/episodes/255-undo-with-paper-trail), 28th February 2011.
[Keep a Paper Trail with PaperTrail](http://www.linux-mag.com/id/7528), Linux Magazine, 16th September 2009.


## Problems

Please use GitHub's [issue tracker](http://github.com/airblade/paper_trail/issues).


## Contributors

Many thanks to:

* [Zachery Hostens](http://github.com/zacheryph)
* [Jeremy Weiskotten](http://github.com/jeremyw)
* [Phan Le](http://github.com/revo)
* [jdrucza](http://github.com/jdrucza)
* [conickal](http://github.com/conickal)
* [Thibaud Guillaume-Gentil](http://github.com/thibaudgg)
* Danny Trelogan
* [Mikl Kurkov](http://github.com/mkurkov)
* [Franco Catena](https://github.com/francocatena)
* [Emmanuel Gomez](https://github.com/emmanuel)
* [Matthew MacLeod](https://github.com/mattmacleod)
* [benzittlau](https://github.com/benzittlau)
* [Tom Derks](https://github.com/EgoH)
* [Jonas Hoglund](https://github.com/jhoglund)
* [Stefan Huber](https://github.com/MSNexploder)
* [thinkcast](https://github.com/thinkcast)
* [Dominik Sander](https://github.com/dsander)
* [Burke Libbey](https://github.com/burke)
* [6twenty](https://github.com/6twenty)
* [nir0](https://github.com/nir0)
* [Eduard Tsech](https://github.com/edtsech)
* [Mathieu Arnold](https://github.com/mat813)
* [Nicholas Thrower](https://github.com/throwern)
* [Benjamin Curtis](https://github.com/stympy)
* [Peter Harkins](https://github.com/pushcx)
* [Mohd Amree](https://github.com/amree)
* [Nikita Cernovs](https://github.com/nikitachernov)
* [Jason Noble](https://github.com/jasonnoble)
* [Jared Mehle](https://github.com/jrmehle)
* [Eric Schwartz](https://github.com/emschwar)
* [Ben Woosley](https://github.com/Empact)
* [Philip Arndt](https://github.com/parndt)
* [Daniel Vydra](https://github.com/dvydra)
* [Byron Bowerman](https://github.com/BM5k)
* [Nicolas Buduroi](https://github.com/budu)
* [Pikender Sharma](https://github.com/pikender)
* [Paul Brannan](https://github.com/cout)
* [Ben Morrall](https://github.com/bmorrall)
* [Yves Senn](https://github.com/senny)
* [Ben Atkins](https://github.com/fullbridge-batkins)
* [Tyler Rick](https://github.com/TylerRick)
* [Bradley Priest](https://github.com/bradleypriest)
* [David Butler](https://github.com/dwbutler)
* [Paul Belt](https://github.com/belt)
* [Vlad Bokov](https://github.com/razum2um)
* [Sean Marcia](https://github.com/SeanMarcia)
* [Chulki Lee](https://github.com/chulkilee)
* [Lucas Souza](https://github.com/lucasas)


## Inspirations

* [Simply Versioned](http://github.com/github/simply_versioned)
* [Acts As Audited](http://github.com/collectiveidea/acts_as_audited)


## Intellectual Property

Copyright (c) 2011 Andy Stewart (boss@airbladesoftware.com).
Released under the MIT licence.
