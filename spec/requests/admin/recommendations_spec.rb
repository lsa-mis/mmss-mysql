# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin recommendations', type: :request do
  let(:admin) { create(:admin) }
  let(:user) { create(:user, :with_applicant_detail) }
  let(:enrollment) { create(:enrollment, user: user) }
  let(:recommendation) { create(:recommendation, enrollment: enrollment) }

  describe 'POST /admin/recommendations/:id/send_request_email' do
    it 'resends the request email as an admin and returns to the (legacy) recommendation page' do
      sign_in admin

      expect do
        post send_request_email_admin_recommendation_path(recommendation)
      end.to change { ActionMailer::Base.deliveries.size }.by(1)

      expect(ActionMailer::Base.deliveries.last.to).to include(recommendation.email)
      expect(response).to redirect_to(legacy_admin_recommendation_path(recommendation))
      expect(flash[:notice]).to include('was sent')
    end

    it 'refuses a signed-in applicant without sending anything' do
      sign_in create(:user)

      post send_request_email_admin_recommendation_path(recommendation)

      expect(response).to redirect_to(new_admin_session_path)
      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it 'refuses anonymous visitors' do
      post send_request_email_admin_recommendation_path(recommendation)

      expect(response).to redirect_to(new_admin_session_path)
    end

    it 'no longer exposes the public GET route' do
      sign_in create(:user)

      get "/send_request_email?recommendation_id=#{recommendation.id}"

      expect(response).to have_http_status(:not_found)
      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it 'performs no mutation on GET' do
      sign_in admin

      get "/admin/recommendations/#{recommendation.id}/send_request_email"

      expect(response).not_to have_http_status(:ok)
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end
end
