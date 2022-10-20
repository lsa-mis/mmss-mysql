require 'rails_helper'

RSpec.describe 'Create user', type: :system do

  before :each do
    load "#{Rails.root}/spec/system/test_seeds.rb" 
  end

  context 'create new user' do
    let(:user) { User.new }
    it 'does not have an id when first instantiated' do expect(user.id).to be nil
    end
  end

  context 'create user' do
    it 'show password mismatch error' do
      visit root_path
      click_on "Sign up"
      sleep(inspection_time=2)
      fill_in 'Email', with: "testuser@test.com"
      fill_in 'Password', with: "secretsecret"
      fill_in 'Password confirmation', with: "secret"
      sleep(inspection_time=2)
      click_on "Sign up"

      expect(page).to have_content("Password confirmation doesn't match Password")
    end
  end

  context 'create user' do
    it 'shows the right content' do
      visit root_path
      click_on "Sign up"
      fill_in 'Email', with: "testuser@test.com"
      fill_in 'Password', with: "secretsecret"
      fill_in 'Password confirmation', with: "secretsecret"
      click_on "Sign up"
      sleep(inspection_time=2)

      expect(page).to have_content("Welcome! You have signed up successfully.")
    end
  end

  context 'create user' do
    it 'shows the right content' do
      @user = FactoryBot.create(:user)
      visit root_path
      click_on "Sign up"
      fill_in 'Email', with: @user.email
      fill_in 'Password', with: @user.password
      fill_in 'Password confirmation', with: @user.password
      click_on "Sign up"
      sleep(inspection_time=2)

      expect(page).to have_content("Email has already been taken")
    end
  end
end