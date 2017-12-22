require 'spec_helper_integration'

module Doorkeeper::OAuth
  describe RefreshTokenRequest do
    let(:server)         { double :server, access_token_expires_in: 2.minutes }
    let!(:refresh_token) { FactoryGirl.create(:access_token, use_refresh_token: true) }
    let(:client)         { refresh_token.application }
    let(:credentials)    { Client::Credentials.new(client.uid, client.secret) }

    subject { RefreshTokenRequest.new server, refresh_token, credentials }

    it 'issues a new token for the client' do
      expect do
        subject.authorize
      end.to change { client.access_tokens.count }.by(1)
    end

    it 'revokes the previous token' do
      expect { subject.authorize } .to change { refresh_token.revoked? }.from(false).to(true)
    end

    it 'requires the refresh token' do
      subject.refresh_token = nil
      subject.validate
      expect(subject.error).to eq(:invalid_request)
    end

    it 'requires credentials to be valid if provided' do
      subject.client = nil
      subject.validate
      expect(subject.error).to eq(:invalid_client)
    end

    it "requires the token's client and current client to match" do
      subject.client = FactoryGirl.create(:application)
      subject.validate
      expect(subject.error).to eq(:invalid_grant)
    end

    it 'rejects revoked tokens' do
      refresh_token.revoke
      subject.validate
      expect(subject.error).to eq(:invalid_request)
    end

    it 'accepts expired tokens' do
      refresh_token.expires_in = -1
      refresh_token.save
      subject.validate
      expect(subject).to be_valid
    end

    context 'clientless access tokens' do
      let!(:refresh_token) { FactoryGirl.create(:clientless_access_token, use_refresh_token: true) }

      subject { RefreshTokenRequest.new server, refresh_token, nil }

      it 'issues a new token without a client' do
        expect { subject.authorize }.to change { Doorkeeper::AccessToken.count }.by(1)
      end
    end

    context 'with scopes' do
      let!(:refresh_token) { FactoryGirl.create(:access_token, use_refresh_token: true, scopes: 'public write') }
      let(:parameters) { {} }
      subject { RefreshTokenRequest.new server, refresh_token, credentials, parameters }

      it 'transfers scopes from the old token to the new token' do
        subject.authorize
        expect(Doorkeeper::AccessToken.last.scopes).to eq([:public, :write])
      end

      it 'reduces scopes to the provided scopes' do
        parameters[:scopes] = 'public'
        subject.authorize
        expect(Doorkeeper::AccessToken.last.scopes).to eq([:public])
      end

      it 'validates that scopes are included in the original access token' do
        parameters[:scopes] = 'public update'

        subject.validate
        expect(subject.error).to eq(:invalid_scope)
      end
    end

  end
end
