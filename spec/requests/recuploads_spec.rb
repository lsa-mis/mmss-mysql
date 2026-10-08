# frozen_string_literal: true

require 'rails_helper'

# Recommender upload flow: no login, the emailed link carries Recommendation#upload_token.
RSpec.describe 'Recommender uploads (token link)', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user, :with_applicant_detail) }
  let(:enrollment) { create(:enrollment, user: user) }
  let!(:recommendation) { create(:recommendation, enrollment: enrollment) }
  let(:token) { recommendation.upload_token }
  let(:letter_params) { { authorname: 'Dr. Test Author', studentname: 'Test Student', letter: 'This is a test recommendation letter.' } }

  describe 'GET /recuploads/new' do
    it 'renders the upload form for a valid token with the applicant name and the token as a hidden field' do
      get new_recupload_path(token: token)

      expect(response).to have_http_status(:ok)
      expect(CGI.unescapeHTML(response.body)).to include(user.applicant_detail.full_name)
      expect(response.body).to include(%(name="token" id="token" value="#{token}"))
      expect(response.body).not_to include('recupload[recommendation_id]')
      expect(response.body).not_to include('name="hash"')
    end

    it 'returns 404 with the error page for an unknown token' do
      get new_recupload_path(token: 'definitely-not-a-token')

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include('We could not find the recommendation request')
    end

    it 'returns 404 when the token is missing or blank, even though recommendations with a NULL token exist' do
      recommendation.invalidate_upload_token!

      get new_recupload_path
      expect(response).to have_http_status(:not_found)

      get new_recupload_path(token: '')
      expect(response).to have_http_status(:not_found)
    end

    it 'no longer resolves the legacy id-based hash link and explains why' do
      get new_recupload_path(hash: "x_nGklDoc2egIkzFxr0U#{recommendation.id}", id: user.applicant_detail.id)

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include('from an older email and no longer works')
      expect(CGI.unescapeHTML(response.body)).not_to include(user.applicant_detail.full_name)
    end

    it 'cannot be reached by guessing: the token never contains the recommendation id' do
      get new_recupload_path(token: recommendation.id.to_s)
      expect(response).to have_http_status(:not_found)

      get new_recupload_path(token: "nGklDoc2egIkzFxr0U#{recommendation.id}")
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 410 with the expired page once the link is past its expiry' do
      recommendation.update_columns(upload_token_expires_at: 1.minute.ago)

      get new_recupload_path(token: token)

      expect(response).to have_http_status(:gone)
      expect(response.body).to include('This recommendation link has expired')
      expect(response.body).to include('mmss@umich.edu')
      expect(response.body).not_to include('recupload[letter]')
    end

    it 'is still valid right up to the expiry time' do
      travel_to(recommendation.upload_token_expires_at - 1.minute) do
        get new_recupload_path(token: token)
        expect(response).to have_http_status(:ok)
      end
    end

    it 'refuses a link whose letter has already been received' do
      recommendation.update_columns(upload_token: 'keptfortest1234567890abc')
      create(:recupload, recommendation: recommendation)
      # the callback cleared the token; simulate a stale copy to hit the explicit guard too
      recommendation.update_columns(upload_token: 'keptfortest1234567890abc')

      get new_recupload_path(token: 'keptfortest1234567890abc')

      expect(response).to redirect_to(recupload_error_path)
      follow_redirect!
      expect(response.body).to include('A recommendation has already been submitted for this user')
    end

    it 'does not log the token' do
      logged = []
      allow(Rails.logger).to receive(:info) { |msg| logged << msg }

      get new_recupload_path(token: 'SECRET-TOKEN-VALUE')

      expect(logged.join("\n")).to include('Recommender upload link not found')
      expect(logged.join("\n")).not_to include('SECRET-TOKEN-VALUE')
    end
  end

  describe 'POST /recuploads' do
    it 'creates the letter for the recommendation the token resolves to, emails both parties and kills the link' do
      expect do
        post recuploads_path, params: { token: token, recupload: letter_params }
      end.to change(Recupload, :count).by(1).and change { ActionMailer::Base.deliveries.size }.by(2)

      expect(response).to redirect_to(recupload_success_path)
      expect(flash[:notice]).to eq('Recommendation was successfully uploaded.')
      expect(Recupload.last.recommendation).to eq(recommendation)
      expect(recommendation.reload.upload_token).to be_nil

      # Second use of the same link
      get new_recupload_path(token: token)
      expect(response).to have_http_status(:not_found)
      expect { post recuploads_path, params: { token: token, recupload: letter_params } }.not_to change(Recupload, :count)
      expect(response).to have_http_status(:not_found)
    end

    it 'is single-use under concurrency: a letter that lands while this request waits for the row lock wins' do
      # Simulate a second submission of the same link committing between the token check in the
      # before_action and the locked re-check inside create.
      allow_any_instance_of(Recommendation).to receive(:lock!).and_wrap_original do |original, *args|
        create(:recupload, recommendation: Recommendation.find(original.receiver.id), authorname: 'First', studentname: 'S', letter: 'First letter')
        original.call(*args)
      end

      expect do
        post recuploads_path, params: { token: token, recupload: letter_params }
      end.to change(Recupload, :count).by(1)

      expect(response).to redirect_to(recupload_error_path)
      expect(flash[:alert]).to eq('A recommendation has already been submitted for this user')
      expect(recommendation.reload.recupload.authorname).to eq('First')
      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it 'treats a database uniqueness conflict as an already-used link' do
      allow_any_instance_of(Recupload).to receive(:save).and_raise(ActiveRecord::RecordNotUnique, 'Duplicate entry')

      expect { post recuploads_path, params: { token: token, recupload: letter_params } }.not_to change(Recupload, :count)

      expect(response).to redirect_to(recupload_error_path)
      expect(flash[:alert]).to eq('A recommendation has already been submitted for this user')
    end

    it 'refuses when an admin reissued the link between the token lookup and the locked insert' do
      allow(Recommendation).to receive(:find_by_upload_token).and_wrap_original do |original, value|
        found = original.call(value)
        found&.issue_upload_token! # "Resend request" lands right after the lookup
        found
      end

      expect { post recuploads_path, params: { token: token, recupload: letter_params } }.not_to change(Recupload, :count)

      expect(response).to redirect_to(recupload_error_path)
      expect(recommendation.reload.upload_token).not_to eq(token)
    end

    it 'ignores a submitted recommendation_id' do
      other = create(:recommendation, enrollment: create(:enrollment, user: create(:user, :with_applicant_detail)))

      post recuploads_path, params: { token: token, recupload: letter_params.merge(recommendation_id: other.id) }

      expect(Recupload.last.recommendation).to eq(recommendation)
      expect(other.reload.recupload).to be_nil
      expect(other.upload_token).to be_present
    end

    it 'uploads a file' do
      post recuploads_path, params: { token: token,
                                      recupload: { authorname: 'Dr. Test Author', studentname: 'Test Student',
                                                   recletter: fixture_file_upload('samplerecletter.pdf', 'application/pdf') } }

      expect(response).to redirect_to(recupload_success_path)
      expect(Recupload.last.recletter).to be_attached
    end

    it 're-renders the form (keeping the token) on validation errors' do
      post recuploads_path, params: { token: token, recupload: { authorname: '', studentname: '', letter: '' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(%(name="token" id="token" value="#{token}"))
      expect(Recupload.count).to eq(0)
      expect(recommendation.reload.upload_token).to eq(token)
    end

    it 'refuses an unknown token without creating anything' do
      expect { post recuploads_path, params: { token: 'nope', recupload: letter_params } }.not_to change(Recupload, :count)
      expect(response).to have_http_status(:not_found)
    end

    it 'refuses an expired token without creating anything' do
      recommendation.update_columns(upload_token_expires_at: 1.minute.ago)

      expect { post recuploads_path, params: { token: token, recupload: letter_params } }.not_to change(Recupload, :count)
      expect(response).to have_http_status(:gone)
    end
  end

  describe 'static pages' do
    it 'serves the success and error pages without a token' do
      get recupload_success_path
      expect(response).to have_http_status(:ok)

      get recupload_error_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('There was an issue processing your recommendation request')
    end
  end
end
