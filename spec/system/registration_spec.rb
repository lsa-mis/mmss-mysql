# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Registration process', type: :system do

  before :each do
    driven_by(:rack_test)
    load "#{Rails.root}/spec/test_seeds.rb"
    @password = 'SecurePassword123!'
    @user = FactoryBot.create(:user, password: @password, password_confirmation: @password)
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
      visit new_user_session_path
      fill_in 'user_email', with: @user.email
      fill_in 'user_password', with: @password
      click_button 'Sign in'

      visit new_applicant_detail_path
      expect(page).to have_content('New Applicant Detail')
    end
  end

end
