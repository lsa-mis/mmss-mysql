# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sidebar progress window', type: :request do
  let!(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year, application_fee_required: true) }
  let(:user) { create(:user, :with_applicant_detail) }
  let!(:enrollment) { create(:enrollment, user: user, campyear: camp_config.camp_year) }

  before do
    CampConfiguration.update_all(active: false)
    camp_config.update!(active: true)
    sign_in user

    enrollment.course_preferences.order(:id).each.with_index(1) do |preference, ranking|
      preference.update!(ranking: ranking)
    end
    create(:recommendation, enrollment: enrollment)
  end

  it 'does not render Account Summary before the application fee is paid' do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Progress Window')
    expect(response.body).not_to include('Account Summary')
  end
end
