# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'layouts/_sidebox.html.erb', type: :view do
  let!(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year, application_fee_required: true) }
  let(:user) { create(:user, :with_applicant_detail) }
  let!(:enrollment) { create(:enrollment, user: user, campyear: camp_config.camp_year) }

  before do
    CampConfiguration.update_all(active: false)
    camp_config.update!(active: true)

    create(:recommendation, enrollment: enrollment)

    allow(view).to receive(:show_applicant_progress_window?).and_return(true)
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:current_enrollment).and_return(enrollment)

    allow(enrollment).to receive(:course_rankings_complete?).and_return(true)
    allow(enrollment).to receive(:payment_portal_ready?).and_return(true)
    allow(enrollment).to receive(:application_fee_required?).and_return(true)
    allow(enrollment).to receive(:application_fee_paid?).and_return(false)

    assign(:current_enrollment, enrollment)
  end

  it 'does not render Account Summary before the application fee is paid' do
    render partial: 'layouts/sidebox'

    expect(rendered).to include('Progress Window')
    expect(rendered).to include('Applicant Details')
    expect(rendered).not_to include('Account Summary')
  end
end
