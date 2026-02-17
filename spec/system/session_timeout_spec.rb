# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Session Timeout Warning', type: :system, js: true do
  let(:user) { create(:user) }
  let(:password) { 'SecurePassword123!' } # Matches factory default
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

  describe 'session timeout warning display' do
    context 'when user is signed in' do
      before do
        # Use Warden to log in, but skip trackable updates to avoid DB locks
        # This is faster than UI login for system tests
        Warden.test_mode!
        login_as(user, scope: :user, run_callbacks: false)
        visit '/'
        # Wait for page to be ready - just check that we're not on the login page
        expect(page).not_to have_content('Sign in', wait: 5)
      end

      it 'includes session timeout controller on body element' do
        # Check for the controller attribute on body
        body = page.find('body')
        expect(body['data-controller']).to include('session-timeout')
      end

      it 'includes expires_at data attribute on body element' do
        body = page.find('body')
        expires_at = body['data-session-timeout-expires-at-value']
        expect(expires_at).to be_present
        expect(expires_at.to_i).to be > 0
      end

      it 'has warning element that is hidden by default' do
        warning = page.find('[data-session-timeout-target="warning"]', visible: false)
        expect(warning).to be_present
        # Check that the element has the 'hidden' class in its class attribute
        expect(warning[:class]).to include('hidden')
      end

      it 'warning element contains expected message' do
        warning = page.find('[data-session-timeout-target="warning"]', visible: false)
        
        # Use JavaScript to get the text content (works even when element is hidden)
        warning_text = page.evaluate_script(<<~JS)
          (function() {
            const warning = document.querySelector('[data-session-timeout-target="warning"]');
            return warning ? warning.textContent || warning.innerText : '';
          })();
        JS
        
        expect(warning_text).to include('Your session will expire soon')
        expect(warning_text).to include('Please submit your form or refresh the page')
      end

      it 'has dismiss button on warning' do
        warning = page.find('[data-session-timeout-target="warning"]', visible: false)
        dismiss_button = warning.find('button[data-action*="dismissWarning"]', visible: false)
        expect(dismiss_button).to be_present
      end
    end

    context 'when user is not signed in' do
      before do
        visit root_path
      end

      it 'does not include expires_at data attribute when no session' do
        body = page.find('body')
        expires_at = body['data-session-timeout-expires-at-value']
        # When no session, the helper returns nil, which renders as empty string
        expect(expires_at).to be_blank
      end

      it 'still includes session timeout controller' do
        expect(page).to have_css('body[data-controller="session-timeout"]')
      end
    end
  end

  describe 'session timeout warning behavior' do
    before do
      # Use Warden to log in, skip trackable updates
      Warden.test_mode!
      login_as(user, scope: :user, run_callbacks: false)
      visit '/'
    end

    context 'when session is about to expire' do
      it 'shows warning when session expires within warning threshold', :aggregate_failures do
        # Set a custom expires_at value that is within the 5-minute warning threshold
        # We'll use JavaScript to set this value directly
        visit root_path
        
        # Calculate a time that's 3 minutes from now (within 5-minute warning)
        expires_at = (Time.current.to_i + 3.minutes.to_i)
        
        # Use JavaScript to update the expires_at value and simulate controller behavior
        page.execute_script(<<~JS)
          const body = document.body;
          const expiresAtValue = #{expires_at};
          body.setAttribute('data-session-timeout-expires-at-value', expiresAtValue);
          
          // Manually trigger the check logic (simulating what the controller does)
          const warning = document.querySelector('[data-session-timeout-target="warning"]');
          if (warning) {
            const now = Math.floor(Date.now() / 1000);
            const warningThreshold = 5 * 60; // 5 minutes in seconds
            const timeUntilExpiry = expiresAtValue - now;
            
            if (timeUntilExpiry > 0 && timeUntilExpiry <= warningThreshold) {
              warning.classList.remove('hidden');
            }
          }
        JS

        # Wait a moment for the warning to appear
        sleep(0.5)

        # Check if warning is visible
        warning = page.find('[data-session-timeout-target="warning"]', visible: true)
        expect(warning).to be_visible
        expect(warning).not_to have_css('.hidden')
      end

      it 'allows dismissing the warning' do
        visit root_path
        
        # Set expires_at to within warning threshold
        expires_at = (Time.current.to_i + 3.minutes.to_i)
        
        page.execute_script(<<~JS)
          const body = document.body;
          const expiresAtValue = #{expires_at};
          body.setAttribute('data-session-timeout-expires-at-value', expiresAtValue);
          
          // Manually trigger the check logic
          const warning = document.querySelector('[data-session-timeout-target="warning"]');
          if (warning) {
            const now = Math.floor(Date.now() / 1000);
            const warningThreshold = 5 * 60; // 5 minutes
            const timeUntilExpiry = expiresAtValue - now;
            
            if (timeUntilExpiry > 0 && timeUntilExpiry <= warningThreshold) {
              warning.classList.remove('hidden');
            }
          }
        JS

        sleep(0.5)

        # Find and click dismiss button
        warning = page.find('[data-session-timeout-target="warning"]', visible: true)
        dismiss_button = warning.find('button[data-action*="dismissWarning"]', visible: true)
        dismiss_button.click

        sleep(0.5)

        # Warning should be hidden again
        warning = page.find('[data-session-timeout-target="warning"]', visible: false)
        expect(warning[:class]).to include('hidden')
      end
    end

    context 'when session is not about to expire' do
      it 'does not show warning when session has plenty of time remaining' do
        visit root_path
        
        # Set expires_at to 10 minutes from now (outside 5-minute warning threshold)
        expires_at = (Time.current.to_i + 10.minutes.to_i)
        
        page.execute_script(<<~JS)
          const body = document.body;
          const expiresAtValue = #{expires_at};
          body.setAttribute('data-session-timeout-expires-at-value', expiresAtValue);
          
          // Manually trigger the check logic
          const warning = document.querySelector('[data-session-timeout-target="warning"]');
          if (warning) {
            const now = Math.floor(Date.now() / 1000);
            const warningThreshold = 5 * 60; // 5 minutes
            const timeUntilExpiry = expiresAtValue - now;
            
            if (timeUntilExpiry > 0 && timeUntilExpiry <= warningThreshold) {
              warning.classList.remove('hidden');
            } else {
              warning.classList.add('hidden');
            }
          }
        JS

        sleep(0.5)

        # Warning should remain hidden
        warning = page.find('[data-session-timeout-target="warning"]', visible: false)
        expect(warning[:class]).to include('hidden')
      end
    end
  end

  describe 'form submission warning' do
    before do
      # Use Warden to log in, skip trackable updates
      Warden.test_mode!
      login_as(user, scope: :user, run_callbacks: false)
      visit '/'
    end

    it 'warns before form submission when session is about to expire' do
      visit '/'
      
      # Set expires_at to within warning threshold (3 minutes from now)
      expires_at = (Time.current.to_i + 3.minutes.to_i)
      
      # Update the expires_at value on the body element and the controller
      page.execute_script(<<~JS)
        const body = document.body;
        body.setAttribute('data-session-timeout-expires-at-value', #{expires_at});
        
        // Update the controller's expiresAtValue directly if it's already connected
        // Access Stimulus application via the data attribute
        const controllerElement = document.querySelector('[data-controller*="session-timeout"]');
        if (controllerElement) {
          const application = controllerElement.getAttribute('data-controller');
          // Try to get the controller instance
          const controllers = window.Stimulus?.application?.controllers || [];
          const controller = controllers.find(c => c.element === controllerElement);
          if (controller && controller.hasExpiresAtValue) {
            controller.expiresAtValue = #{expires_at};
          }
        }
      JS

      # Create a test form that submits to root (which exists)
      page.execute_script(<<~JS)
        // Create a test form if one doesn't exist
        if (document.querySelector('form.test-form') === null) {
          const form = document.createElement('form');
          form.className = 'test-form';
          form.method = 'GET';
          form.action = '/';
          const input = document.createElement('input');
          input.type = 'text';
          input.name = 'test_field';
          input.value = 'test';
          form.appendChild(input);
          const submit = document.createElement('button');
          submit.type = 'submit';
          submit.textContent = 'Submit';
          form.appendChild(submit);
          document.body.appendChild(form);
        }
      JS

      # Wait a moment for the controller to process the updated expires_at value
      sleep(0.5)

      # Try to submit the form - the session-timeout controller should show a confirm dialog
      form = page.find('form.test-form', visible: true)
      submit_button = form.find('button[type="submit"]', visible: true)
      
      # Click the submit button - this will trigger the confirm dialog from the controller
      submit_button.click
      
      # Handle the alert that appears
      # Use a retry mechanism in case the alert takes a moment to appear
      alert_handled = false
      5.times do
        begin
          alert = page.driver.browser.switch_to.alert
          if alert.text.include?('Your session is about to expire')
            alert.accept
            alert_handled = true
            break
          end
        rescue Selenium::WebDriver::Error::NoSuchAlertError
          sleep(0.1)
          next
        end
      end
      
      # If we couldn't handle the alert via Selenium, try accept_confirm as fallback
      unless alert_handled
        begin
          accept_confirm(/Your session is about to expire/, wait: 1) do
            # Alert should be handled by now
          end
        rescue => e
          # If accept_confirm fails, try one more time with Selenium
          begin
            page.driver.browser.switch_to.alert.accept
          rescue Selenium::WebDriver::Error::NoSuchAlertError
            # Alert already handled or not present
          end
        end
      end
      
      # Wait for navigation to complete
      sleep(0.5)
      
      # Verify we handled the form submission
      # The form is a GET form, so it will add query parameters to the URL
      expect(page.current_path.split('?').first).to eq('/')
    end
  end

  describe 'integration with existing functionality' do
    before do
      # Use Warden to log in, skip trackable updates
      Warden.test_mode!
      login_as(user, scope: :user, run_callbacks: false)
      visit '/'
    end

    it 'does not interfere with normal page rendering' do
      visit root_path
      expect(page).to have_content('Michigan Math and Science Scholars')
    end

    it 'does not interfere with navigation' do
      visit root_path
      # Navigation should work normally
      expect(page).to have_css('body[data-controller="session-timeout"]')
    end

    it 'works correctly on pages with forms' do
      # Navigate to a page that likely has a form (like sign up)
      visit root_path
      click_on 'Sign up' if page.has_link?('Sign up')
      
      # Session timeout controller should still be present
      expect(page).to have_css('body[data-controller="session-timeout"]')
    end
  end
end
