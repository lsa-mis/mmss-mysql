require 'rails_helper'

RSpec.describe 'Registration process', type: :system do

  before :each do
    load "#{Rails.root}/spec/test_seeds.rb" 
    @user = FactoryBot.create(:user)
    login_as(@user)
  end

  context 'login to registration' do
    it 'shows the right content' do
      visit root_path
      click_on "Returning User - Sign In"
      fill_in 'Email', with: @user.email
      fill_in 'Password', with: @user.password
      click_on "Sign in"

      expect(page).to have_content('As you advance through the application process, these directions will be updated')
      sleep(inspection_time=2)
      click_on "Registration"
      expect(page).to have_content('New Applicant Detail')
      sleep(inspection_time=2)
    end
  end

end