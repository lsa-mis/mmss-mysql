# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create user', type: :system do
  include ApplicationHelper

  context 'create new user' do
    let(:user) { User.new }
    it 'does not have an id when first instantiated' do expect(user.id).to be nil
    end
  end

  # Run successful sign-up before the password-mismatch example; the latter leaves
  # process/session state that breaks the next sign-up when run in the full suite.
  context 'create user' do
    it 'shows the right content' do
      # Use unique email to avoid collision when tests run in different order
      email = "testuser_#{SecureRandom.hex(8)}@test.com"

      # Ensure only one active camp so registration_open? is deterministic
      CampConfiguration.update_all(active: false)
      create(:camp_configuration,
             camp_year: 2026,
             application_open: Date.current - 30.days,
             application_close: Date.current + 90.days,
             active: true)

      visit new_user_registration_path

      expect(page).to have_field('Email')
      fill_in 'Email', with: email
      fill_in 'Password', with: "secretsecret"
      fill_in 'Password confirmation', with: "secretsecret"
      within("form[action*='user']") { click_button "Sign up" }

      expect(page).to have_content("Welcome! You have signed up successfully.")
    end
  end

  context 'create user' do
    it 'shows the right content' do
      # Create test data directly in the test
      create(:camp_configuration,
             camp_year: 2027,
             application_open: Date.current - 30.days,
             application_close: Date.current + 90.days,
             active: true)

      @user = FactoryBot.create(:user)
      visit new_user_registration_path

      expect(page).to have_field('Email')
      fill_in 'Email', with: @user.email
      fill_in 'Password', with: @user.password
      fill_in 'Password confirmation', with: @user.password
      click_button "Sign up"

      expect(page).to have_content("Email has already been taken")
    end
  end

  # Password mismatch example last: it leaves process/session state that breaks
  # the next sign-up when run in the full suite.
  context 'create user' do
    it 'show password mismatch error' do
      # Create test data directly in the test
      create(:camp_configuration,
             camp_year: 2025,
             application_open: Date.current - 30.days,
             application_close: Date.current + 90.days,
             active: true)

      visit new_user_registration_path

      expect(page).to have_field('Email')
      fill_in 'Email', with: "testuser@test.com"
      fill_in 'Password', with: "secretsecret"
      fill_in 'Password confirmation', with: "secret"
      click_button "Sign up"

      expect(page).to have_content("Password confirmation doesn't match Password")
    end
  end
end
