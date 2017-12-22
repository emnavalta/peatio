require 'spec_helper_integration'

describe Doorkeeper, 'configuration' do
  subject { Doorkeeper.configuration }

  describe 'resource_owner_authenticator' do
    it 'sets the block that is accessible via authenticate_resource_owner' do
      block = proc {}
      Doorkeeper.configure do
        orm DOORKEEPER_ORM
        resource_owner_authenticator &block
      end
      expect(subject.authenticate_resource_owner).to eq(block)
    end
  end

  describe 'admin_authenticator' do
    it 'sets the block that is accessible via authenticate_admin' do
      block = proc {}
      Doorkeeper.configure do
        orm DOORKEEPER_ORM
        admin_authenticator &block
      end
      expect(subject.authenticate_admin).to eq(block)
    end
  end

  describe 'access_token_expires_in' do
    it 'has 2 hours by default' do
      expect(subject.access_token_expires_in).to eq(2.hours)
    end

    it 'can change the value' do
      Doorkeeper.configure do
        orm DOORKEEPER_ORM
        access_token_expires_in 4.hours
      end
      expect(subject.access_token_expires_in).to eq(4.hours)
    end

    it 'can be set to nil' do
      Doorkeeper.configure do
        orm DOORKEEPER_ORM
        access_token_expires_in nil
      end
      expect(subject.access_token_expires_in).to be_nil
    end
  end

  describe 'scopes' do
    it 'has default scopes' do
      Doorkeeper.configure do
        orm DOORKEEPER_ORM
        default_scopes :public
      end
      expect(subject.default_scopes).to include('public')
    end

    it 'has optional scopes' do
      Doorkeeper.configure do
        orm DOORKEEPER_ORM
        optional_scopes :write, :update
      end
      expect(subject.optional_scopes).to include('write', 'update')
    end

    it 'has all scopes' do
      Doorkeeper.configure do
        orm DOORKEEPER_ORM
        default_scopes  :normal
        optional_scopes :admin
      end
      expect(subject.scopes).to include('normal', 'admin')
    end
  end

  describe 'use_refresh_token' do
    it 'is false by default' do
      expect(subject.refresh_token_enabled?).to be_falsey
    end

    it 'can change the value' do
      Doorkeeper.configure do
        orm DOORKEEPER_ORM
        use_refresh_token
      end
      expect(subject.refresh_token_enabled?).to be_truthy
    end

    it "does not includes 'refresh_token' in authorization_response_types" do
      expect(subject.token_grant_types).not_to include 'refresh_token'
    end

    context "is enabled" do
      before do
        Doorkeeper.configure {
          orm DOORKEEPER_ORM
          use_refresh_token
        }
      end

      it "includes 'refresh_token' in authorization_response_types" do
        expect(subject.token_grant_types).to include 'refresh_token'
      end
    end
  end

  describe 'client_credentials' do
    it 'has defaults order' do
      expect(subject.client_credentials_methods).to eq([:from_basic, :from_params])
    end

    it 'can change the value' do
      Doorkeeper.configure do
        orm DOORKEEPER_ORM
        client_credentials :from_digest, :from_params
      end
      expect(subject.client_credentials_methods).to eq([:from_digest, :from_params])
    end
  end

  describe 'access_token_credentials' do
    it 'has defaults order' do
      expect(subject.access_token_methods).to eq([:from_bearer_authorization, :from_access_token_param, :from_bearer_param])
    end

    it 'can change the value' do
      Doorkeeper.configure do
        orm DOORKEEPER_ORM
        access_token_methods :from_access_token_param, :from_bearer_param
      end
      expect(subject.access_token_methods).to eq([:from_access_token_param, :from_bearer_param])
    end
  end

  describe 'enable_application_owner' do
    it 'is disabled by default' do
      expect(Doorkeeper.configuration.enable_application_owner?).not_to be_truthy
    end

    context 'when enabled without confirmation' do
      before do
        Doorkeeper.configure do
          orm DOORKEEPER_ORM
          enable_application_owner
        end
      end
      it 'adds support for application owner' do
        expect(Doorkeeper::Application.new).to respond_to :owner
      end
      it 'Doorkeeper.configuration.confirm_application_owner? returns false' do
        expect(Doorkeeper.configuration.confirm_application_owner?).not_to be_truthy
      end
    end

    context 'when enabled with confirmation set to true' do
      before do
        Doorkeeper.configure do
          orm DOORKEEPER_ORM
          enable_application_owner confirmation: true
        end
      end
      it 'adds support for application owner' do
        expect(Doorkeeper::Application.new).to respond_to :owner
      end
      it 'Doorkeeper.configuration.confirm_application_owner? returns true' do
        expect(Doorkeeper.configuration.confirm_application_owner?).to be_truthy
      end
    end
  end

  describe 'wildcard_redirect_uri' do
    it 'is disabled by default' do
      Doorkeeper.configuration.wildcard_redirect_uri.should be_falsey
    end
  end

  describe 'realm' do
    it 'is \'Doorkeeper\' by default' do
      expect(Doorkeeper.configuration.realm).to eq('Doorkeeper')
    end

    it 'can change the value' do
      Doorkeeper.configure do
        orm DOORKEEPER_ORM
        realm 'Example'
      end
      expect(subject.realm).to eq('Example')
    end
  end

  describe "grant_flows" do
    it "is set to all grant flows by default" do
      expect(Doorkeeper.configuration.grant_flows).to eq [
        'authorization_code',
        'implicit',
        'password',
        'client_credentials'
      ]
    end

    it "can change the value" do
      Doorkeeper.configure {
        orm DOORKEEPER_ORM
        grant_flows [ 'authorization_code', 'implicit' ]
      }
      expect(subject.grant_flows).to eq ['authorization_code', 'implicit']
    end

    context "when including 'authorization_code'" do
      before do
        Doorkeeper.configure {
          orm DOORKEEPER_ORM
          grant_flows ['authorization_code']
        }
      end

      it "includes 'code' in authorization_response_types" do
        expect(subject.authorization_response_types).to include 'code'
      end

      it "includes 'authorization_code' in token_grant_types" do
        expect(subject.token_grant_types).to include 'authorization_code'
      end
    end

    context "when including 'implicit'" do
      before do
        Doorkeeper.configure {
          orm DOORKEEPER_ORM
          grant_flows ['implicit']
        }
      end

      it "includes 'token' in authorization_response_types" do
        expect(subject.authorization_response_types).to include 'token'
      end
    end

    context "when including 'password'" do
      before do
        Doorkeeper.configure {
          orm DOORKEEPER_ORM
          grant_flows ['password']
        }
      end

      it "includes 'password' in token_grant_types" do
        expect(subject.token_grant_types).to include 'password'
      end
    end

    context "when including 'client_credentials'" do
      before do
        Doorkeeper.configure {
          orm DOORKEEPER_ORM
          grant_flows ['client_credentials']
        }
      end

      it "includes 'client_credentials' in token_grant_types" do
        expect(subject.token_grant_types).to include 'client_credentials'
      end
    end
  end

  describe 'test_redirect_uri' do
    it 'can change the native_redirect_uri value' do
      Doorkeeper.configure do
        orm DOORKEEPER_ORM
        test_redirect_uri 'foo'
      end
      expect(subject.native_redirect_uri).to eq('foo')
    end
  end

  it 'raises an exception when configuration is not set' do
    old_config = Doorkeeper.configuration
    Doorkeeper.module_eval do
      @config = nil
    end

    expect do
      Doorkeeper.configuration
    end.to raise_error Doorkeeper::MissingConfiguration

    Doorkeeper.module_eval do
      @config = old_config
    end
  end
end
