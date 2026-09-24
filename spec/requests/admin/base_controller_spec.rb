# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::BaseController authentication', type: :request do
  describe 'GET /admin' do
    it 'redirects anonymous visitors to the admin login page' do
      get admin_root_path

      expect(response).to redirect_to(new_admin_session_path)
    end

    it 'does not accept a signed-in applicant (User) as an admin' do
      sign_in create(:user)

      get admin_root_path

      expect(response).to redirect_to(new_admin_session_path)
    end

    it 'renders the admin layout for a signed-in admin' do
      admin = create(:admin)
      sign_in admin

      get admin_root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('MMSS Admin')
      expect(response.body).to include(admin.email)
      expect(response.body).to include(destroy_admin_session_path)
      expect(response.body).to include('/assets/admin-')
      expect(response.body).not_to include('active_admin')
      expect(response.body).to include(%(data-turbo="false" href="#{legacy_admin_root_path}"))
    end

    it 'shows the four menu groups in the sidebar' do
      sign_in create(:admin)

      get admin_root_path

      %w[Applicant\ Info Camp\ Setup Logins\ Info Dashboard Reports Applications Comments].each do |label|
        expect(response.body).to include(label)
      end
    end
  end

  describe 'legacy ActiveAdmin' do
    it 'serves ActiveAdmin at /legacy_admin' do
      sign_in create(:admin)

      get legacy_admin_root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('active_admin')
    end

    # Every menu resource is ported now; the catch-all still covers old bookmarks of any unmatched
    # /admin path (e.g. ActiveAdmin's /admin/applications/:id/edit variants) until the cutover PR.
    it 'redirects unmatched /admin paths to /legacy_admin (keeping the query string)' do
      sign_in create(:admin)

      get '/admin/legacy_only_page?order=id_desc'

      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to('/legacy_admin/legacy_only_page?order=id_desc')
    end

    it 'keeps the admin_* helpers used elsewhere in the app' do
      expect(admin_root_path).to eq('/admin')
      expect(admin_applications_path).to eq('/admin/applications')
      expect(admin_application_path(1)).to eq('/admin/applications/1')
      expect(edit_admin_application_path(1)).to eq('/admin/applications/1/edit')
      expect(new_admin_session_path).to eq('/admin/login')
      expect(destroy_admin_session_path).to eq('/admin/logout')
      expect(admin_recommendation_path(1)).to eq('/admin/recommendations/1')
      expect(admin_financial_aid_request_path(1)).to eq('/admin/financial_aid_requests/1')
      expect(admin_reports_path).to eq('/admin/reports')
      expect(admin_report_path('offer_accepted_with_balance_due')).to eq('/admin/reports/offer_accepted_with_balance_due')
    end
  end

  describe 'record not found' do
    it 'redirects to the dashboard with an alert' do
      sign_in create(:admin)

      get admin_application_path(0)

      expect(response).to redirect_to(admin_root_path)
      follow_redirect!
      expect(response.body).to include('could not be found')
    end
  end
end
