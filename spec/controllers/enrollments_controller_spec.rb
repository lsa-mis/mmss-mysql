# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EnrollmentsController, type: :controller do
  describe 'GET #show' do
    let(:user) { create(:user) }
    let(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year) }

    before do
      CampConfiguration.update_all(active: false)
      camp_config.update(active: true)
      sign_in user
    end

    context 'when user has no current camp year enrollment' do
      it 'redirects to root with alert and does not raise' do
        get :show, params: { id: 1 }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('No current enrollment found.')
      end
    end

    context 'when user has a current camp year enrollment' do
      let!(:enrollment) { create(:enrollment, user: user, campyear: camp_config.camp_year) }

      it 'renders show successfully' do
        get :show, params: { id: enrollment.id }
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
