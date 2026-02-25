# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FeedbacksController, type: :controller do
  let(:user) { create(:user) }
  let(:valid_attributes) do
    { genre: 'page_error', message: 'The submit button did not work on the application page.' }
  end
  let(:invalid_attributes) do
    { genre: nil, message: nil }
  end

  describe 'GET #new' do
    context 'when not signed in' do
      it 'redirects to sign in' do
        get :new
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when signed in as user' do
      before { sign_in user }

      it 'returns success' do
        get :new
        expect(response).to have_http_status(:ok)
      end

      it 'assigns a new feedback for the current user' do
        get :new
        expect(assigns(:feedback)).to be_a_new(Feedback)
        expect(assigns(:feedback).user_id).to eq(user.id)
      end
    end
  end

  describe 'POST #create' do
    context 'when not signed in' do
      it 'redirects to sign in' do
        post :create, params: { feedback: valid_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'does not create a feedback' do
        expect {
          post :create, params: { feedback: valid_attributes }
        }.not_to change(Feedback, :count)
      end
    end

    context 'when signed in as user' do
      before { sign_in user }

      context 'with valid params' do
        it 'creates a new Feedback' do
          expect {
            post :create, params: { feedback: valid_attributes }
          }.to change(Feedback, :count).by(1)
        end

        it 'assigns the current user as feedback owner' do
          post :create, params: { feedback: valid_attributes }
          expect(Feedback.last.user_id).to eq(user.id)
        end

        it 'redirects to root with notice' do
          post :create, params: { feedback: valid_attributes }
          expect(response).to redirect_to(root_path)
          expect(flash[:notice]).to eq('Feedback was successfully created.')
        end

        it 'sends feedback email' do
          expect {
            post :create, params: { feedback: valid_attributes }
          }.to change { ActionMailer::Base.deliveries.count }.by(1)
        end
      end

      context 'with invalid params (missing required fields)' do
        it 'does not create a feedback' do
          expect {
            post :create, params: { feedback: invalid_attributes }
          }.not_to change(Feedback, :count)
        end

        it 're-renders new with errors' do
          post :create, params: { feedback: invalid_attributes }
          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:new)
          expect(assigns(:feedback).errors).not_to be_empty
        end
      end

      context 'with message too long' do
        let(:too_long_attributes) do
          { genre: 'page_error', message: 'x' * 256 }
        end

        it 'does not create a feedback' do
          expect {
            post :create, params: { feedback: too_long_attributes }
          }.not_to change(Feedback, :count)
        end

        it 're-renders new with message length error' do
          post :create, params: { feedback: too_long_attributes }
          expect(response).to render_template(:new)
          expect(assigns(:feedback).errors[:message].first).to match(/too long.*255/)
        end
      end
    end
  end
end
