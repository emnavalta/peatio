# Globalize Changelog

## 4.0.0.alpha.5 (2014-1-4)
* Fix issue where globalize breaks has_many through when model called with `where` (thanks [Paul McMahon](https://github.com/pwim)).
* Modify dup so that translations are copied, and remove custom clone code to conform to Rails/AR semantics (thanks [Paul McMahon](https://github.com/pwim)).

## 4.0.0.alpha.4 (2013-12-30)
* Add this changelog.
* Add contributing guidelines.
* Group options into more structured methods in act_macro.rb.
* Remove dynamic finder code from globalize3, no longer used in AR4.
* Get hash of translated attributes by calling attribute on model, not translation.
* Define translation readers/writers in separate methods.
* Test against AR 4.1 and AR 4.0.
* Switch to minitest-reporters for colouring output from minitest.
* Remove find_or_instantiator_by_attributes which is no longer used in AR4.
* Set I18n.available_locales in tests to avoid deprecation message.
* Reorganize specs into describe blocks to clarify object of specs.

## 4.0.0.alpha.3 (2013-12-18)

* Move ActiveRecord::Relation#where_values_hash patch into globalize relation class to avoid monkeypatching.
* Add Code Climate Score (thanks [BrandonMathis](https://github.com/BrandonMathis)).
* Query using Globalize.fallbacks rather than locale only when fetching a record (thanks [@huoxito](https://github.com/huoxito)).
* Use a module (QueryMethods) rather than a class for overriding functionality of ActiveRecord::Relation.
* Use ActiveRecord::Relation#extending! to extend ActiveRecord::Base#relation with QueryMethods, works with associations as well.

## 4.0.0.alpha.2 (2013-10-24)

* Add license to gemspec.
* Update references to ActiveRecord 3 -> ActiveRecord.
* Replace references to globalize3 with globalize and remove references to ActiveRecord 3.x.
* Document `3-0-stable` branch in readme.
* Convert test syntax to MiniTest::Spec.
* Extract easy accessors functionality, moved to new [globalize-accessors](https://github.com/globalize/globalize-accessors) gem.
* Check that `first` is not nil before reloading translations, fixes [#282](https://github.com/globalize/globalize/issues/282).
* Duplicate arguments in query finders before modifying them, fixes [#284](https://github.com/globalize/globalize/issues/284).
* Add test for `find_or_create_by` with translated attribute.

## 4.0.0.alpha.1 (2013-10-9)

* Initial release of Rails 4-compatible gem.

## 3.0.3 (2013-12-26)

* Ensure that foreign key is always set when saving translations (thanks [Andrew Feng](https://github.com/mingliangfeng)).
* Patch I18n to add back I18n.interpolate after it was removed (accidentally?) in v0.5.2 (see [svenfuchs/i18n#232](https://github.com/svenfuchs/i18n/issues/232). Hopefully this patch will be temporary.
* Explicitly test compatibility with FriendlyId to avoid issues like [#306](https://github.com/globalize/globalize/issues/306).
* Only override ActiveRecord::Base#relation to patch where_values_hash if using AR >= 3.2.1.

## 3.0.2 (2013-12-07)

* Alias `ActiveRecord::Base#relation` and include query method overrides as module, fixes [#306](https://github.com/globalize/globalize/issues/306) and [norman/friendly_id#485](https://github.com/norman/friendly_id/issues/485).

## 3.0.1 (2013-11-07)

* Move `ActiveRecord::Relation#where_values_hash` patch to Globalize-specific Relation class that inherits from `ActiveRecord::Relation` to fix compatibility issue with Squeel ([#288](https://github.com/globalize/globalize/issues/288)).
* Use FriendlyId pattern for overriding `ActiveRecord::Base#relation` to avoid conflict.
* Remove `:null => false` condition on reference to parent model in translation table migration, partial fix for [refinery/refinerycms#2450](https://github.com/refinery/refinerycms/issues/2450).

## 3.0.0 (2013-10-24)

* Initial release with new version numbering.
