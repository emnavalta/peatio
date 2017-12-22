require 'spec_helper'

describe "PaperTrail RSpec Helper" do
  context 'default' do
    it 'should have versioning off by default' do
      ::PaperTrail.should_not be_enabled
    end
    it 'should turn versioning on in a `with_versioning` block' do
      ::PaperTrail.should_not be_enabled
      with_versioning do
        ::PaperTrail.should be_enabled
      end
      ::PaperTrail.should_not be_enabled
    end

    context "error within `with_versioning` block" do
      it "should revert the value of `PaperTrail.enabled?` to it's previous state" do
        ::PaperTrail.should_not be_enabled
        expect { with_versioning { raise } }.to raise_error
        ::PaperTrail.should_not be_enabled
      end
    end
  end

  context '`versioning: true`', :versioning => true do
    it 'should have versioning on by default' do
      ::PaperTrail.should be_enabled
    end
    it 'should keep versioning on after a with_versioning block' do
      ::PaperTrail.should be_enabled
      with_versioning do
        ::PaperTrail.should be_enabled
      end
      ::PaperTrail.should be_enabled
    end
  end

  context '`with_versioning` block at class level' do
    it { ::PaperTrail.should_not be_enabled }

    with_versioning do
      it 'should have versioning on by default' do
        ::PaperTrail.should be_enabled
      end
    end
    it 'should not leak the `enabled?` state into successive tests' do
      ::PaperTrail.should_not be_enabled
    end
  end

  describe :whodunnit do
    before(:all) { ::PaperTrail.whodunnit = 'foobar' }

    it "should get set to `nil` by default" do
      ::PaperTrail.whodunnit.should be_nil
    end
  end

  describe :controller_info do
    before(:all) { ::PaperTrail.controller_info = {:foo => 'bar'} }

    it "should get set to an empty hash before each test" do
      ::PaperTrail.controller_info.should == {}
    end
  end
end
