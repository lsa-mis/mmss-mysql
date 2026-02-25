# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Feedback workflow', type: :system do
  it 'redirects to sign in when visiting feedback form while not signed in' do
    visit new_feedback_path
    expect(page).to have_content('Sign in')
    expect(page).to have_content('You need to sign in or sign up before continuing')
  end
end
