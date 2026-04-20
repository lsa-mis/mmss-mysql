# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Course preferences enrollment resolution', type: :request do
  let!(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year) }

  before do
    CampConfiguration.update_all(active: false)
    camp_config.update!(active: true)
  end

  it 'redirects to home when the user has no current-year enrollment (no NoMethodError)' do
    user = create(:user)
    sign_in user

    get course_preferences_path

    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to eq('No current enrollment found.')
  end

  it 'redirects to home when enrollment_id does not belong to the current user' do
    owner = create(:user)
    enrollment = create(:enrollment, user: owner, campyear: camp_config.camp_year)
    other = create(:user)
    sign_in other

    get enrollment_course_preferences_path(enrollment)

    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to eq('No current enrollment found.')
  end
end
