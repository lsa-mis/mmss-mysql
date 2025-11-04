# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Registration process', type: :system do

  before :each do
    load "#{Rails.root}/spec/test_seeds.rb"
    # Use factory default password
    @password = 'SecurePassword123!'
    @user = FactoryBot.create(:user)
    # Ensure an active camp exists so auth links render
    CampConfiguration.update_all(active: false)
    camp = CampConfiguration.find_or_create_by!(camp_year: Date.current.year) do |c|
      c.application_open = Date.new(Date.current.year, 1, 1)
      c.application_close = Date.new(Date.current.year, 12, 31)
      c.priority = Date.new(Date.current.year, 3, 31)
      c.application_materials_due = Date.new(Date.current.year, 5, 31)
      c.camper_acceptance_due = Date.new(Date.current.year, 6, 15)
      c.application_fee_cents = 10_000
      c.application_fee_required = true
      c.offer_letter = 'Default offer letter content'
      c.reject_letter = 'Default rejection letter content'
      c.waitlist_letter = 'Default waitlist letter content'
    end
    camp.update!(active: true)
  end

  context 'login to registration' do
    it 'shows the right content' do
      # Ensure user exists and can authenticate programmatically
      @user.reload
      expect(@user.valid_password?(@password)).to be true

      visit new_user_session_path

      # Wait for login form to be visible
      expect(page).to have_field('Email')
      expect(page).to have_field('Password')

      # Fill in credentials
      fill_in 'Email', with: @user.email
      fill_in 'Password', with: @password

      # Submit the form
      click_button "Sign in"

      # Wait for either success (content appears) or failure (error message)
      # Capybara will wait up to default_wait_time (usually 2 seconds)
      begin
        # Try to wait for success content first
        expect(page).to have_content('As you advance through the application process, these directions will be updated', wait: 5)
      rescue RSpec::Expectations::ExpectationNotMetError
        # If that fails, check if we got an error
        if page.has_content?('Invalid Email or password')
          # Debug: print what we found
          puts "\n=== AUTHENTICATION DEBUG ==="
          puts "User email: #{@user.email}"
          puts "User persisted: #{@user.persisted?}"
          puts "Password valid (programmatically): #{@user.valid_password?(@password)}"
          puts "User in DB: #{User.find_by(email: @user.email).present?}"
          puts "=============================\n"
          raise "Authentication failed - see debug output above"
        else
          raise
        end
      end

      click_on "Registration"
      expect(page).to have_content('New Applicant Detail')
    end
  end

end
