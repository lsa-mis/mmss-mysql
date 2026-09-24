# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin dashboard', type: :request do
  let(:admin) { create(:admin) }

  before { sign_in admin }

  context 'without an active camp' do
    before { CampConfiguration.update_all(active: false) }

    it 'shows the no-active-camp notification' do
      get admin_root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('No active camps')
    end
  end

  context 'with an active camp' do
    let(:user) { create(:user, :with_applicant_detail) }
    let!(:enrollment) { create(:enrollment, :accepted, user: user) }
    let!(:payment) { create(:payment, user: user, camp_year: enrollment.campyear, total_amount: '12345') }
    let!(:financial_aid) { create(:financial_aid, :pending, enrollment: enrollment) }
    let!(:campnote) { create(:campnote, opendate: 1.day.ago, closedate: 1.day.from_now, notetype: 'alert', note: 'Dorm check-in moved') }

    it 'renders the seven dashboard panels' do
      get admin_root_path

      expect(response).to have_http_status(:ok)
      body = response.body

      expect(body).to include("Recent Applications for #{enrollment.campyear} Camp")
      expect(body).to include(user.applicant_detail.full_name)
      expect(body).to include(admin_application_path(enrollment))

      expect(body).to include("Recent Payments for #{enrollment.campyear} Camp")
      expect(body).to include('$123.45')

      expect(body).to include('Offer Accepted with Balance Due')
      expect(body).to include("Parent: #{user.applicant_detail.parentname}")

      expect(body).to include('Financial Aid Requests')
      expect(body).to include(enrollment.display_name)

      expect(body).to include('Session Stats')
      expect(body).to include('Active Camp Note')
      expect(body).to include('Dorm check-in moved')
      expect(body).to include('Resources')
      expect(body).to include('Admin Documentation')
    end
  end
end
