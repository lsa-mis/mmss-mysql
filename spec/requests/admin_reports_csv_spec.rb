# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin report CSV formula neutralization', type: :request do
  let(:admin) { create(:admin) }
  let!(:camp_configuration) { create(:camp_configuration, :current_year) }

  before { sign_in admin }

  describe 'GET /admin/reports/finaid_with_app_and_offer_status' do
    it 'prefixes formula-like applicant names and emails in the CSV export' do
      user = create(:user, email: '=cmd@example.com')
      create(
        :applicant_detail,
        user: user,
        firstname: '=1+2',
        lastname: '+Doe',
        parentemail: '@SUM(A1)@example.com',
        phone: '-1+1',
        parentphone: '555-0100'
      )
      enrollment = create(
        :enrollment,
        user: user,
        campyear: camp_configuration.camp_year,
        application_status: 'application complete',
        offer_status: 'accepted'
      )
      create(:financial_aid, enrollment: enrollment, status: 'awarded', amount_cents: 5000)

      get admin_reports_finaid_with_app_and_offer_status_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("'=1+2")
      expect(response.body).to include("'+Doe")
      expect(response.body).to include("'=cmd@example.com")
    end

    it 'leaves ordinary applicant names unchanged' do
      user = create(:user, email: 'safe.student@example.com')
      create(
        :applicant_detail,
        user: user,
        firstname: 'Ada',
        lastname: 'Lovelace',
        parentphone: '555-0100'
      )
      enrollment = create(
        :enrollment,
        user: user,
        campyear: camp_configuration.camp_year,
        application_status: 'application complete'
      )
      create(:financial_aid, enrollment: enrollment, status: 'pending', amount_cents: 1000)

      get admin_reports_finaid_with_app_and_offer_status_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Ada')
      expect(response.body).to include('Lovelace')
      expect(response.body).to include('safe.student@example.com')
      expect(response.body).not_to include("'Ada")
    end
  end

  describe 'GET /admin/reports/enrolled_with_addresses' do
    it 'prefixes formula-like address and parent fields in the CSV export' do
      user = create(:user, email: 'addr.student@example.com')
      create(
        :applicant_detail,
        user: user,
        firstname: 'Sam',
        lastname: 'Student',
        address1: '=HYPERLINK("http://evil.example")',
        parentname: '+Parent',
        parentemail: '-evil@example.com',
        parentphone: '@SUM(A1)'
      )
      create(
        :enrollment,
        user: user,
        campyear: camp_configuration.camp_year,
        application_status: 'enrolled'
      )

      get admin_reports_enrolled_with_addresses_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("'=HYPERLINK(\"http://evil.example\")")
      expect(response.body).to include("'+Parent")
      expect(response.body).to include("'-evil@example.com")
      expect(response.body).to include("'@SUM(A1)")
    end
  end
end
