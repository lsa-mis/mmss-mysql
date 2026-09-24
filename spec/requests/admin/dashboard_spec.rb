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
    # A successful first payment moves the application to `submitted` (Payment#set_status), which
    # would drop it from the balance-due panel; a declined payment still appears in "Recent Payments".
    let!(:payment) { create(:payment, user: user, camp_year: enrollment.campyear, total_amount: '2550', transaction_status: '2') }
    let!(:financial_aid) { create(:financial_aid, :pending, enrollment: enrollment) }
    let!(:campnote) { create(:campnote, opendate: 1.day.ago, closedate: 1.day.from_now, notetype: 'alert', note: 'Dorm check-in moved') }

    it 'renders when a pending request or payment belongs to a user without applicant details' do
      bare_user = create(:user)
      bare_enrollment = create(:enrollment, :accepted, user: bare_user)
      create(:financial_aid, :pending, enrollment: bare_enrollment)
      create(:payment, user: bare_user, camp_year: bare_enrollment.campyear, transaction_status: '2')

      get admin_root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(bare_user.email)
    end

    it 'renders the seven dashboard panels' do
      get admin_root_path

      expect(response).to have_http_status(:ok)
      body = response.body

      expect(body).to include("Recent Applications for #{enrollment.campyear} Camp")
      expect(CGI.unescapeHTML(body)).to include(user.applicant_detail.full_name)
      expect(body).to include(admin_application_path(enrollment))

      expect(body).to include("Recent Payments for #{enrollment.campyear} Camp")
      expect(body).to include('$25.50')

      expect(body).to include('Offer Accepted with Balance Due')
      expect(CGI.unescapeHTML(body)).to include("Parent: #{user.applicant_detail.parentname}")

      expect(body).to include('Financial Aid Requests')
      expect(CGI.unescapeHTML(body)).to include(enrollment.display_name)

      expect(body).to include('Session Stats')
      expect(body).to include('Active Camp Note')
      expect(body).to include('Dorm check-in moved')
      expect(body).to include('Resources')
      expect(body).to include('Admin Documentation')
    end
  end
end
