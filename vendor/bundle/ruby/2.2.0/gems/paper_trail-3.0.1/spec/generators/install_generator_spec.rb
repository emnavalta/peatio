require 'spec_helper'
require 'generator_spec/test_case'
require File.expand_path('../../../lib/generators/paper_trail/install_generator', __FILE__)

describe PaperTrail::InstallGenerator, :type => :generator do
  include GeneratorSpec::TestCase
  destination File.expand_path('../tmp', __FILE__)

  after(:all) { prepare_destination } # cleanup the tmp directory

  describe "no options" do
    before(:all) do
      prepare_destination
      run_generator
    end
  
    it "generates a migration for creating the 'versions' table" do
      destination_root.should have_structure {
        directory 'db' do
          directory 'migrate' do
            migration 'create_versions' do
              contains 'class CreateVersions'
              contains 'def change'
              contains 'create_table :versions do |t|'
            end
          end
        end
      }
    end
  end

  describe "`--with-changes` option set to `true`" do
    before(:all) do
      prepare_destination
      run_generator %w(--with-changes)
    end

    it "generates a migration for creating the 'versions' table" do
      destination_root.should have_structure {
        directory 'db' do
          directory 'migrate' do
            migration 'create_versions' do
              contains 'class CreateVersions'
              contains 'def change'
              contains 'create_table :versions do |t|'
            end
          end
        end
      }
    end

    it "generates a migration for adding the 'object_changes' column to the 'versions' table" do
      destination_root.should have_structure {
        directory 'db' do
          directory 'migrate' do
            migration 'add_object_changes_to_versions' do
              contains 'class AddObjectChangesToVersions'
              contains 'def change'
              contains 'add_column :versions, :object_changes, :text'
            end
          end
        end
      }
    end
  end

end
