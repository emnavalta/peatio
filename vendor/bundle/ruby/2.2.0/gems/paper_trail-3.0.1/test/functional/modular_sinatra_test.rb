require 'test_helper'
require 'sinatra/base'

# --- Tests for modular `Sinatra::Base` style ----
class BaseApp < Sinatra::Base
  ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => File.expand_path('../../dummy/db/test.sqlite3', __FILE__))
  register PaperTrail::Sinatra

  get '/test' do
    Widget.create!(:name => 'foo')
    'Hello'
  end

  def current_user
    @current_user ||= OpenStruct.new(:id => 'foobar').tap do |obj|
      # Invoking `id` returns the `object_id` value in Ruby18 unless specifically overwritten
      def obj.id; 'foobar'; end if RUBY_VERSION.to_f < 1.9
    end
  end
end

class ModularSinatraTest < ActionDispatch::IntegrationTest
  include Rack::Test::Methods

  def app
    @app ||= BaseApp
  end

  test 'baseline' do
    assert_nil Widget.first
    assert_nil Widget.create.versions.first.whodunnit
  end

  context "`PaperTrail::Sinatra` in a `Sinatra::Base` application" do
  
    should "sets the `user_for_paper_trail` from the `current_user` method" do
      get '/test'
      assert_equal 'Hello', last_response.body
      widget = Widget.first
      assert_not_nil widget
      assert_equal 'foo', widget.name
      assert_equal 1, widget.versions.size
      assert_equal 'foobar', widget.versions.first.whodunnit
    end

  end
end
