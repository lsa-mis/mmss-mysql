# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  # Create a test controller to test ApplicationController behavior
  controller do
    def test_action
      render plain: 'success'
    end
  end

  before do
    routes.draw do
      get 'test_action', to: 'anonymous#test_action'
      post 'test_action', to: 'anonymous#test_action'
    end
  end

  describe 'CSRF token error handling' do
    context 'when user is signed in' do
      let(:user) { create(:user) }

      before { sign_in user }

      it 'redirects to referrer with appropriate flash message' do
        request.env['HTTP_REFERER'] = '/some_page'
        allow(controller).to receive(:verify_authenticity_token).and_raise(ActionController::InvalidAuthenticityToken)
        
        post :test_action
        
        expect(response).to redirect_to('/some_page')
        expect(flash[:alert]).to eq('Your session expired. Please try submitting again. If the problem persists, please sign out and sign back in.')
      end

      it 'redirects to root_path when referrer is not available' do
        allow(controller).to receive(:verify_authenticity_token).and_raise(ActionController::InvalidAuthenticityToken)
        
        post :test_action
        
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Your session expired. Please try submitting again. If the problem persists, please sign out and sign back in.')
      end
    end

    context 'when admin is signed in' do
      let(:admin) { create(:admin) }

      before { sign_in admin }

      it 'redirects to referrer with appropriate flash message' do
        request.env['HTTP_REFERER'] = '/admin_page'
        allow(controller).to receive(:verify_authenticity_token).and_raise(ActionController::InvalidAuthenticityToken)
        
        post :test_action
        
        expect(response).to redirect_to('/admin_page')
        expect(flash[:alert]).to eq('Your session expired. Please try submitting again. If the problem persists, please sign out and sign back in.')
      end
    end

    context 'when faculty is signed in' do
      let(:faculty) do
        # Stub Course.current_camp before creating faculty to satisfy validation
        # The validation extracts uniqname from email (part before @)
        faculty = build(:faculty, email: "prof1@university.edu")
        uniqname = faculty.email.split('@').first
        course_relation = double('CourseRelation')
        allow(course_relation).to receive(:pluck).with(:faculty_uniqname).and_return([uniqname])
        allow(Course).to receive(:current_camp).and_return(course_relation)
        faculty.save!
        faculty
      end

      before { sign_in faculty }

      it 'redirects to referrer with appropriate flash message' do
        request.env['HTTP_REFERER'] = '/faculty_page'
        allow(controller).to receive(:verify_authenticity_token).and_raise(ActionController::InvalidAuthenticityToken)
        
        post :test_action
        
        expect(response).to redirect_to('/faculty_page')
        expect(flash[:alert]).to eq('Your session expired. Please try submitting again. If the problem persists, please sign out and sign back in.')
      end
    end

    context 'when no user is signed in' do
      it 'redirects to sign in page with appropriate flash message' do
        allow(controller).to receive(:verify_authenticity_token).and_raise(ActionController::InvalidAuthenticityToken)
        
        post :test_action
        
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to eq('Your session expired. Please sign in again to continue.')
      end

      it 'stores location for GET requests' do
        allow(controller).to receive(:verify_authenticity_token).and_raise(ActionController::InvalidAuthenticityToken)
        
        get :test_action, params: {}
        
        expect(session['user_return_to']).to eq('/test_action')
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'does not store location for POST requests' do
        allow(controller).to receive(:verify_authenticity_token).and_raise(ActionController::InvalidAuthenticityToken)
        
        post :test_action
        
        expect(session['user_return_to']).to be_nil
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
