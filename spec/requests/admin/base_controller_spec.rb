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
      expect(response.body).not_to include('legacy_admin')
    end

    it 'shows the four menu groups in the sidebar' do
      sign_in create(:admin)

      get admin_root_path

      %w[Applicant\ Info Camp\ Setup Logins\ Info Dashboard Reports Applications Comments].each do |label|
        expect(response.body).to include(label)
      end
    end
  end

  describe 'after the ActiveAdmin cutover' do
    it 'redirects the former /legacy_admin URLs to the new admin' do
      get '/legacy_admin'
      expect(response).to redirect_to('/admin')
      expect(response).to have_http_status(:moved_permanently)

      get '/legacy_admin/applications/1/edit?order=id_desc'
      expect(response).to redirect_to('/admin')
    end

    it 'no longer redirects unmatched /admin paths anywhere (404)' do
      sign_in create(:admin)

      get '/admin/legacy_only_page?order=id_desc'

      expect(response).to have_http_status(:not_found)
    end

    it 'defines no legacy_admin route helpers or ActiveAdmin routes' do
      helpers = Rails.application.routes.named_routes.names.map(&:to_s)
      expect(helpers.grep(/legacy_admin/)).to be_empty

      controllers = Rails.application.routes.routes.filter_map { |r| r.defaults[:controller] }.uniq
      expect(controllers.grep(/legacy_admin|active_admin/)).to be_empty
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
