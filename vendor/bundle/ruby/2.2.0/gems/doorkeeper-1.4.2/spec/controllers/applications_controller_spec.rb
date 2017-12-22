require 'spec_helper_integration'

module Doorkeeper
  describe ApplicationsController do
    context 'when admin is not authenticated' do
      before do
        allow(Doorkeeper.configuration).to receive(:authenticate_admin).and_return(proc do
          redirect_to main_app.root_url
        end)
      end

      it 'redirects as set in Doorkeeper.authenticate_admin' do
        get :index
        expect(response).to redirect_to(controller.main_app.root_url)
      end

      it 'does not create application' do
        expect do
          post :create, application: {
            name: 'Example',
            redirect_uri: 'http://example.com' }
        end.to_not change { Doorkeeper::Application.count }
      end
    end

    context 'when admin is authenticated' do
      before do
        allow(Doorkeeper.configuration).to receive(:authenticate_admin).and_return(->(arg) { true })
      end

      it 'creates application' do
        expect do
          post :create, application: {
            name: 'Example',
            redirect_uri: 'http://example.com' }
        end.to change { Doorkeeper::Application.count }.by(1)
        expect(response).to be_redirect
      end

      it 'does not allow mass assignment of uid or secret' do
        application = FactoryGirl.create(:application)
        put :update, id: application.id, application: {
          uid: '1A2B3C4D',
          secret: '1A2B3C4D' }

        expect(application.reload.uid).not_to eq '1A2B3C4D'
      end

      it 'updates application' do
        application = FactoryGirl.create(:application)
        put :update, id: application.id, application: {
          name: 'Example',
          redirect_uri: 'http://example.com' }
        expect(application.reload.name).to eq 'Example'
      end
    end

  end
end
