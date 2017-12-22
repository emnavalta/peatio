require 'spec_helper_integration'

module Doorkeeper::OAuth
  describe PasswordAccessTokenRequest do
    let(:server) { double :server, default_scopes: Doorkeeper::OAuth::Scopes.new, access_token_expires_in: 2.hours, refresh_token_enabled?: false }
    let(:credentials) { Client::Credentials.new(client.uid, client.secret) }
    let(:client) { FactoryGirl.create(:application) }
    let(:owner)  { double :owner, id: 99 }

    subject do
      PasswordAccessTokenRequest.new(server, credentials, owner)
    end

    it 'issues a new token for the client' do
      expect do
        subject.authorize
      end.to change { client.access_tokens.count }.by(1)
    end

    it 'issues a new token without a client' do
      expect do
        subject.credentials = nil
        subject.authorize
      end.to change { Doorkeeper::AccessToken.count }.by(1)
    end

    it 'does not issue a new token with an invalid client' do
      expect do
        subject.client = nil
        subject.authorize
      end.to_not change { Doorkeeper::AccessToken.count }

      expect(subject.error).to eq(:invalid_client)
    end

    it 'requires the owner' do
      subject.resource_owner = nil
      subject.validate
      expect(subject.error).to eq(:invalid_resource_owner)
    end

    it 'optionally accepts the client' do
      subject.credentials = nil
      expect(subject).to be_valid
    end

    it 'creates token even when there is already one (default)' do
      FactoryGirl.create(:access_token, application_id: client.id, resource_owner_id: owner.id)
      expect do
        subject.authorize
      end.to change { Doorkeeper::AccessToken.count }.by(1)
    end

    it 'skips token creation if there is already one' do
      Doorkeeper.configuration.stub(:reuse_access_token).and_return(true)
      FactoryGirl.create(:access_token, application_id: client.id, resource_owner_id: owner.id)
      expect do
        subject.authorize
      end.to_not change { Doorkeeper::AccessToken.count }
    end

    describe 'with scopes' do
      subject do
        PasswordAccessTokenRequest.new(server, client, owner, scope: 'public')
      end

      it 'validates the current scope' do
        allow(server).to receive(:scopes).and_return(Doorkeeper::OAuth::Scopes.from_string('another'))
        subject.validate
        expect(subject.error).to eq(:invalid_scope)
      end

      it 'creates the token with scopes' do
        allow(server).to receive(:scopes).and_return(Doorkeeper::OAuth::Scopes.from_string('public'))
        expect do
          subject.authorize
        end.to change { Doorkeeper::AccessToken.count }.by(1)
        expect(Doorkeeper::AccessToken.last.scopes).to include('public')
      end
    end
  end
end
