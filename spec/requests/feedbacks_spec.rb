# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Feedbacks', type: :request do
  let(:user) { create(:user) }
  let(:valid_attributes) do
    { genre: 'page_error', message: 'The submit button did not work on the application page.' }
  end

  describe 'GET /feedbacks/new' do
    context 'when not signed in' do
      it 'redirects to sign in' do
        get new_feedback_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when signed in' do
      before { sign_in user }

      it 'returns success and shows the form' do
        get new_feedback_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Send Feedback')
        expect(response.body).to include('genre')
        expect(response.body).to include('message')
        expect(response.body).to include(Feedback::MESSAGE_MAX_LENGTH.to_s)
      end
    end
  end

  describe 'POST /feedbacks' do
    context 'when not signed in' do
      it 'redirects to sign in and does not create feedback' do
        expect {
          post feedbacks_path, params: { feedback: valid_attributes }
        }.not_to change(Feedback, :count)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when signed in' do
      before { sign_in user }

      it 'creates feedback and redirects to root' do
        expect {
          post feedbacks_path, params: { feedback: valid_attributes }
        }.to change(Feedback, :count).by(1)

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include('Feedback was successfully created')

        feedback = Feedback.last
        expect(feedback.user_id).to eq(user.id)
        expect(feedback.genre).to eq('page_error')
        expect(feedback.message).to eq(valid_attributes[:message])
      end

      it 'rejects feedback with message over 255 characters' do
        long_message = { genre: 'suggestion', message: 'x' * 256 }
        expect {
          post feedbacks_path, params: { feedback: long_message }
        }.not_to change(Feedback, :count)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('too long')
      end

      it 'rejects feedback with missing genre' do
        params = { genre: '', message: 'Some message' }
        expect {
          post feedbacks_path, params: { feedback: params }
        }.not_to change(Feedback, :count)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('error')
      end

      it 'rejects feedback with missing message' do
        params = { genre: 'page_error', message: '' }
        expect {
          post feedbacks_path, params: { feedback: params }
        }.not_to change(Feedback, :count)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('error')
      end
    end
  end

  describe 'GET /feedbacks (index)' do
    it 'redirects to root' do
      sign_in user
      get feedbacks_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe 'GET /feedbacks/:id (show)' do
    let(:feedback) { create(:feedback, user: user) }

    it 'redirects to root' do
      sign_in user
      get feedback_path(feedback)
      expect(response).to redirect_to(root_path)
    end
  end
end
