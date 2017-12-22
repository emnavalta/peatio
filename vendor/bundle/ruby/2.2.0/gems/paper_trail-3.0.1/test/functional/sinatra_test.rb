require 'test_helper'
# require 'sinatra/main'

# --- Tests for non-modular `Sinatra::Application` style ----
class Sinatra::Application
  ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => File.expand_path('../../dummy/db/test.sqlite3', __FILE__))
  register PaperTrail::Sinatra # we shouldn't actually need this line if I'm not mistaken but the tests seem to fail without it ATM

  get '/test' do
    Widget.create!(:name => 'bar')
    'Hai'
  end

  def current_user
    @current_user ||= OpenStruct.new(:id => 'raboof').tap do |obj|
      # Invoking `id` returns the `object_id` value in Ruby18 unless specifically overwritten
      def obj.id; 'raboof'; end if RUBY_VERSION.to_f < 1.9
    end
  end

end

class SinatraTest < ActionDispatch::IntegrationTest
  include Rack::Test::Methods

  def app
    @app ||= Sinatra::Application
  end

  test 'baseline' do
    assert_nil Widget.first
    assert_nil Widget.create.versions.first.whodunnit
  end

  context "`PaperTrail::Sinatra` in a `Sinatra::Application` application" do

    should "sets the `user_for_paper_trail` from the `current_user` method" do
      get '/test'
      assert_equal 'Hai', last_response.body
      widget = Widget.first
      assert_not_nil widget
      assert_equal 'bar', widget.name
      assert_equal 1, widget.versions.size
      assert_equal 'raboof', widget.versions.first.whodunnit
    end

  end
end
