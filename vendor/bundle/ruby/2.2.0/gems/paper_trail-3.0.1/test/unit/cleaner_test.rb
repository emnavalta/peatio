require 'test_helper'

class PaperTrailCleanerTest < ActiveSupport::TestCase

  setup do
    @animals = [@animal = Animal.new, @dog = Dog.new, @cat = Cat.new]
    @animals.each do |animal|
      3.times { animal.update_attribute(:name, Faker::Name.name) }
    end
  end

  test 'Baseline' do
    assert_equal 9, PaperTrail::Version.count
    @animals.each { |animal| assert_equal 3, animal.versions.size }
  end

  context '`clean_versions!` method' do
    should 'be extended by `PaperTrail` module' do
      assert_respond_to PaperTrail, :clean_versions!
    end

    context 'No options provided' do
      should 'removes extra versions for each item' do
        PaperTrail.clean_versions!
        assert_equal 3, PaperTrail::Version.count
        @animals.each { |animal| assert_equal 1, animal.versions.size }
      end

      should 'removes the earliest version(s)' do
        most_recent_version_names = @animals.map { |animal| animal.versions.last.reify.name }
        PaperTrail.clean_versions!
        assert_equal most_recent_version_names, @animals.map { |animal| animal.versions.last.reify.name }
      end
    end

    context '`:keeping` option' do
      should 'modifies the number of versions ommitted from destruction' do
        PaperTrail.clean_versions!(:keeping => 2)
        assert_equal 6, PaperTrail::Version.all.count
        @animals.each { |animal| assert_equal 2, animal.versions.size }
      end
    end

    context '`:date` option' do
      setup do
        @animal.versions.each { |ver| ver.update_attribute(:created_at, ver.created_at - 1.day) }
        @date = @animal.versions.first.created_at.to_date
        @animal.update_attribute(:name, Faker::Name.name)
      end

      should 'restrict the versions destroyed to those that were created on the date provided' do
        assert_equal 10, PaperTrail::Version.count
        assert_equal 4, @animal.versions.size
        assert_equal 3, @animal.versions_between(@date, @date + 1.day).size
        PaperTrail.clean_versions!(:date => @date)
        assert_equal 8, PaperTrail::Version.count
        assert_equal 2, @animal.versions(true).size
        assert_equal @date, @animal.versions.first.created_at.to_date
        assert_not_same @date, @animal.versions.last.created_at.to_date
      end
    end

    context '`:item_id` option' do
      context 'single ID received' do
        should 'restrict the versions destroyed to the versions for the Item with that ID' do
          PaperTrail.clean_versions!(:item_id => @animal.id)
          assert_equal 1, @animal.versions.size
          assert_equal 7, PaperTrail::Version.count
        end
      end

      context "collection of ID's received" do
        should "restrict the versions destroyed to the versions for the Item with those ID's" do
          PaperTrail.clean_versions!(:item_id => [@animal.id, @dog.id])
          assert_equal 1, @animal.versions.size
          assert_equal 1, @dog.versions.size
          assert_equal 5, PaperTrail::Version.count
        end
      end
    end

    context 'options combinations' do # additional tests to cover combinations of options
      context '`:date`' do
        setup do
          [@animal, @dog].each do |animal|
            animal.versions.each { |ver| ver.update_attribute(:created_at, ver.created_at - 1.day) }
            animal.update_attribute(:name, Faker::Name.name)
          end
          @date = @animal.versions.first.created_at.to_date
        end

        should 'Baseline' do
          assert_equal 11, PaperTrail::Version.count
          [@animal, @dog].each do |animal|
            assert_equal 4, animal.versions.size
            assert_equal 3, animal.versions.between(@date, @date+1.day).size
          end
        end

        context 'and `:keeping`' do
          should 'restrict cleaning properly' do
            PaperTrail.clean_versions!(:date => @date, :keeping => 2)
            [@animal, @dog].each do |animal|
              animal.versions.reload # reload the association to pick up the destructions made by the `Cleaner`
              assert_equal 3, animal.versions.size
              assert_equal 2, animal.versions.between(@date, @date+1.day).size
            end
            assert_equal 9, PaperTrail::Version.count # ensure that the versions for the `@cat` instance wasn't touched
          end
        end

        context 'and `:item_id`' do
          should 'restrict cleaning properly' do
            PaperTrail.clean_versions!(:date => @date, :item_id => @dog.id)
            @dog.versions.reload # reload the association to pick up the destructions made by the `Cleaner`
            assert_equal 2, @dog.versions.size
            assert_equal 1, @dog.versions.between(@date, @date+1.day).size
            assert_equal 9, PaperTrail::Version.count # ensure the versions for other animals besides `@animal` weren't touched
          end
        end

        context ', `:item_id`, and `:keeping`' do
          should 'restrict cleaning properly' do
            PaperTrail.clean_versions!(:date => @date, :item_id => @dog.id, :keeping => 2)
            @dog.versions.reload # reload the association to pick up the destructions made by the `Cleaner`
            assert_equal 3, @dog.versions.size
            assert_equal 2, @dog.versions.between(@date, @date+1.day).size
            assert_equal 10, PaperTrail::Version.count # ensure the versions for other animals besides `@animal` weren't touched
          end
        end
      end

      context '`:keeping` and `:item_id`' do
        should 'restrict cleaning properly' do
          PaperTrail.clean_versions!(:keeping => 2, :item_id => @animal.id)
          assert_equal 2, @animal.versions.size
          assert_equal 8, PaperTrail::Version.count # ensure the versions for other animals besides `@animal` weren't touched
        end
      end
    end

  end # clean_versions! method
end
