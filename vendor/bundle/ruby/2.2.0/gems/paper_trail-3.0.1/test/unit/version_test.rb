require 'test_helper'

class PaperTrail::VersionTest < ActiveSupport::TestCase
  setup do
    change_schema
    @animal = Animal.create
    assert PaperTrail::Version.creates.present?
  end

  context "PaperTrail::Version.creates" do
    should "return only create events" do
      PaperTrail::Version.creates.each do |version|
        assert_equal "create", version.event
      end
    end
  end

  context "PaperTrail::Version.updates" do
    setup {
      @animal.update_attributes(:name => 'Animal')
      assert PaperTrail::Version.updates.present?
    }

    should "return only update events" do
      PaperTrail::Version.updates.each do |version|
        assert_equal "update", version.event
      end
    end
  end

  context "PaperTrail::Version.destroys" do
    setup {
      @animal.destroy
      assert PaperTrail::Version.destroys.present?
    }

    should "return only destroy events" do
      PaperTrail::Version.destroys.each do |version|
        assert_equal "destroy", version.event
      end
    end
  end

  context "PaperTrail::Version.not_creates" do
    setup {
      @animal.update_attributes(:name => 'Animal')
      @animal.destroy
      assert PaperTrail::Version.not_creates.present?
    }

    should "return all versions except create events" do
      PaperTrail::Version.not_creates.each do |version|
        assert_not_equal "create", version.event
      end
    end
  end

  context "PaperTrail::Version.subsequent" do
    setup { 2.times { @animal.update_attributes(:name => Faker::Lorem.word) } }

    context "receiving a TimeStamp" do
      should "return all versions that were created before the Timestamp; descendingly by order of the `PaperTrail.timestamp_field`" do
        value = PaperTrail::Version.subsequent(1.hour.ago)
        assert_equal value, @animal.versions.to_a
        assert_not_nil value.to_sql.match(/ORDER BY versions.created_at ASC\z/)
      end
    end

    context "receiving a `PaperTrail::Version`" do
      should "grab the Timestamp from the version and use that as the value" do
        value = PaperTrail::Version.subsequent(@animal.versions.first)
        assert_equal value, @animal.versions.to_a.tap { |assoc| assoc.shift }
        # This asssertion can't pass in Ruby18 because the `strftime` method doesn't accept the %6 (milliseconds) command
        if RUBY_VERSION.to_f >= 1.9 and not defined?(JRUBY_VERSION)
          assert_not_nil value.to_sql.match(/WHERE \(versions.created_at > '#{@animal.versions.first.send(PaperTrail.timestamp_field).strftime("%F %T.%6N")}'\)/)
        end
      end
    end
  end

  context "PaperTrail::Version.preceding" do
    setup { 2.times { @animal.update_attributes(:name => Faker::Lorem.word) } }

    context "receiving a TimeStamp" do
      should "return all versions that were created before the Timestamp; descendingly by order of the `PaperTrail.timestamp_field`" do
        value = PaperTrail::Version.preceding(Time.now)
        assert_equal value, @animal.versions.reverse
        assert_not_nil value.to_sql.match(/ORDER BY versions.created_at DESC\z/)
      end
    end

    context "receiving a `PaperTrail::Version`" do
      should "grab the Timestamp from the version and use that as the value" do
        value = PaperTrail::Version.preceding(@animal.versions.last)
        assert_equal value, @animal.versions.to_a.tap { |assoc| assoc.pop }.reverse
        # This asssertion can't pass in Ruby18 because the `strftime` method doesn't accept the %6 (milliseconds) command
        if RUBY_VERSION.to_f >= 1.9 and not defined?(JRUBY_VERSION)
          assert_not_nil value.to_sql.match(/WHERE \(versions.created_at < '#{@animal.versions.last.send(PaperTrail.timestamp_field).strftime("%F %T.%6N")}'\)/)
        end
      end
    end
  end
end
