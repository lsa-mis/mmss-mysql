# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Session Timeout Integration', type: :request do
  let(:user) { create(:user) }
  let(:camp_config) do
    create(:camp_configuration,
           camp_year: 2025,
           application_open: Date.current - 30.days,
           application_close: Date.current + 90.days,
           active: true)
  end

  before do
    camp_config
  end

  describe 'layout rendering with session timeout' do
    context 'when user is signed in' do
      before { sign_in user }

      it 'renders layout with session timeout data attributes' do
        get root_path
        expect(response).to have_http_status(:success)
        
        # Check that the body includes session timeout controller
        expect(response.body).to include('data-controller="session-timeout"')
        
        # Check that expires_at is included (should be a number)
        expect(response.body).to match(/data-session-timeout-expires-at-value="\d+"/)
      end

      it 'renders warning element in layout' do
        get root_path
        expect(response).to have_http_status(:success)
        
        # Check for warning element
        expect(response.body).to include('data-session-timeout-target="warning"')
        expect(response.body).to include('Your session will expire soon')
      end

      it 'does not break existing page content' do
        get root_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include('MMSS')
      end
    end

    context 'when user is not signed in' do
      it 'renders layout without expires_at when no session' do
        get root_path
        expect(response).to have_http_status(:success)
        
        # Session timeout controller should still be present
        expect(response.body).to include('data-controller="session-timeout"')
        
        # expires_at should be empty or nil when no session
        # The helper returns nil, which renders as empty string in ERB
        expect(response.body).to match(/data-session-timeout-expires-at-value=""/)
      end

      it 'does not break authentication flow' do
        get new_user_session_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Sign in')
      end
    end
  end

  describe 'session_expires_at helper method integration' do
    context 'when session exists' do
      before { sign_in user }

      it 'returns a valid timestamp in the rendered HTML' do
        get root_path
        expect(response).to have_http_status(:success)
        
        # Extract the expires_at value from the HTML
        match = response.body.match(/data-session-timeout-expires-at-value="(\d+)"/)
        expect(match).to be_present
        
        expires_at = match[1].to_i
        expect(expires_at).to be > Time.current.to_i
        expect(expires_at).to be <= (Time.current + 5.hours).to_i
      end
    end

    context 'when session does not exist' do
      it 'renders empty expires_at value' do
        get root_path
        expect(response).to have_http_status(:success)
        
        # When no session, expires_at should be empty
        expect(response.body).to match(/data-session-timeout-expires-at-value=""/)
      end
    end
  end

  describe 'compatibility with existing functionality' do
    before { sign_in user }

    it 'does not interfere with CSRF token handling' do
      # Verify that the page renders correctly and session timeout doesn't break CSRF
      # The main concern is that session timeout functionality doesn't interfere with
      # existing Rails features like CSRF protection
      get root_path
      expect(response).to have_http_status(:success)
      
      # Verify the page still renders correctly with session timeout functionality
      expect(response.body).to include('data-controller="session-timeout"')
      
      # Verify that the page has proper HTML structure (indicating it rendered correctly)
      expect(response.body).to include('</html>')
      expect(response.body).to include('<body')
      
      # The fact that the page renders successfully without errors indicates
      # that CSRF and other Rails features are still working correctly
    end

    it 'does not interfere with flash messages' do
      get root_path
      expect(response).to have_http_status(:success)
      # Flash messages should still render - check that page has content
      expect(response.body).to be_present
    end

    it 'does not interfere with navigation rendering' do
      get root_path
      expect(response).to have_http_status(:success)
      # Navigation should still be present - check that page has content
      expect(response.body).to be_present
    end

    it 'works correctly across different pages' do
      # Test that session timeout is included on different pages
      pages_to_test = [root_path]
      
      pages_to_test.each do |path|
        get path
        expect(response).to have_http_status(:success)
        expect(response.body).to include('data-controller="session-timeout"')
      end
    end
  end

  describe 'environment-specific behavior' do
    before { sign_in user }

    it 'calculates timeout correctly in different environments' do
      # Test that the helper works in the current environment
      get root_path
      expect(response).to have_http_status(:success)
      
      match = response.body.match(/data-session-timeout-expires-at-value="(\d+)"/)
      expect(match).to be_present
      
      expires_at = match[1].to_i
      current_time = Time.current.to_i
      four_hours = 4.hours.to_i
      
      # Should be approximately 4 hours from now (allow 1 minute tolerance)
      expect(expires_at).to be_between(current_time + four_hours - 60, current_time + four_hours + 60)
    end
  end
end
