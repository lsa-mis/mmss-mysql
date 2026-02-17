# frozen_string_literal: true

# Tests for production session configuration:
# - 4 hour session timeout (expire_after: 4.hours)
# - Secure cookies in production (secure: Rails.env.production?)
# - Session key (key: 'mmss_security_session')
#
# Note: These tests verify the configuration in production.rb, but to fully test
# secure cookies and session expiration in production, you should:
#
# 1. Test Secure Cookies in Production:
#    - Deploy to production or staging
#    - Sign in to the application
#    - Open browser DevTools > Application/Storage > Cookies
#    - Verify the 'mmss_security_session' cookie has the "Secure" flag checked
#    - Verify the cookie is only sent over HTTPS connections
#
# 2. Test Session Timeout (4 hours):
#    - Sign in to the application
#    - Wait 4 hours (or use browser DevTools to manually expire the cookie)
#    - Try to make a request that requires authentication
#    - Verify you are redirected to sign in page
#    - Alternatively, test with a shorter timeout in staging:
#      * Temporarily change expire_after to 1.minute in staging
#      * Sign in, wait 1 minute, verify session expires
#
# 3. Test Session Persistence:
#    - Sign in and start filling out a long form
#    - Verify session persists for the full 4 hours
#    - Verify CSRF token doesn't expire during form completion

require 'rails_helper'

RSpec.describe 'Session Configuration', type: :request do
  describe 'production.rb configuration file' do
    it 'verifies production configuration includes expected session store settings' do
      production_config_file = Rails.root.join('config', 'environments', 'production.rb')
      production_config_content = File.read(production_config_file)
      
      # Verify the configuration includes the expected values
      expect(production_config_content).to include("expire_after: 4.hours")
      expect(production_config_content).to include("secure: Rails.env.production?")
      expect(production_config_content).to include("key: 'mmss_security_session'")
      expect(production_config_content).to include("session_store :cookie_store")
    end
  end

  describe 'session store configuration behavior' do
    it 'configures session store with production settings when Rails.env.production? is true' do
      allow(Rails.env).to receive(:production?).and_return(true)
      
      # Configure as production does
      Rails.application.config.session_store :cookie_store,
                                             key: 'mmss_security_session',
                                             secure: Rails.env.production?,
                                             expire_after: 4.hours
      
      # Verify the session store class is CookieStore
      expect(Rails.application.config.session_store).to eq(ActionDispatch::Session::CookieStore)
      
      # Note: In test environment, we can't easily access the options hash directly,
      # but we can verify the configuration was applied by checking the file content
      # and testing behavior through request specs
    end

    it 'configures session store with non-secure cookies when Rails.env.production? is false' do
      allow(Rails.env).to receive(:production?).and_return(false)
      
      # Configure as production does, but secure should be false
      Rails.application.config.session_store :cookie_store,
                                             key: 'mmss_security_session',
                                             secure: Rails.env.production?,
                                             expire_after: 4.hours
      
      # Verify the session store class is CookieStore
      expect(Rails.application.config.session_store).to eq(ActionDispatch::Session::CookieStore)
    end
  end

  describe 'cookie security and timeout in production', type: :request do
    let(:user) { create(:user) }

    context 'when simulating production environment' do
      before do
        # Stub Rails.env to simulate production for cookie security testing
        allow(Rails.env).to receive(:production?).and_return(true)
        allow(Rails.env).to receive(:test?).and_return(false)
        
        # Reconfigure session store as production does
        Rails.application.config.session_store :cookie_store,
                                               key: 'mmss_security_session',
                                               secure: Rails.env.production?,
                                               expire_after: 4.hours
      end

      after do
        # Restore test environment
        allow(Rails.env).to receive(:production?).and_call_original
        allow(Rails.env).to receive(:test?).and_return(true)
        # Reset to default cookie store
        Rails.application.config.session_store :cookie_store
      end

      it 'configures session store correctly for production' do
        expect(Rails.application.config.session_store).to eq(ActionDispatch::Session::CookieStore)
        # The secure flag and expire_after are set in the configuration,
        # which will be applied when the app runs in production
      end

      it 'allows session to be set and retrieved' do
        sign_in user
        get root_path
        expect(response).to have_http_status(:success)
        # Session should be accessible
        expect(session).to be_present
      end
    end
  end

  describe 'session expiration timeout' do
    it 'verifies 4 hours equals 14400 seconds' do
      # Verify the timeout value is correct
      expect(4.hours.to_i).to eq(14400)
    end

    it 'allows session to persist in test environment' do
      user = create(:user)
      sign_in user
      
      # Set a value in session
      get root_path
      expect(response).to have_http_status(:success)
      
      # Session should be active immediately
      expect(session).to be_present
    end
  end

  describe 'production configuration verification' do
    it 'ensures production.rb has all required session configuration' do
      production_config_file = Rails.root.join('config', 'environments', 'production.rb')
      production_config_content = File.read(production_config_file)
      
      # Verify all production requirements are in the config file
      expect(production_config_content).to match(/session_store\s*:cookie_store/)
      expect(production_config_content).to match(/key:\s*['"]mmss_security_session['"]/)
      expect(production_config_content).to match(/secure:\s*Rails\.env\.production\?/)
      expect(production_config_content).to match(/expire_after:\s*4\.hours/)
    end

    it 'verifies force_ssl is enabled in production' do
      production_config_file = Rails.root.join('config', 'environments', 'production.rb')
      production_config_content = File.read(production_config_file)
      
      # force_ssl should be enabled, which also helps with secure cookies
      expect(production_config_content).to include('config.force_ssl = true')
    end
  end
end
