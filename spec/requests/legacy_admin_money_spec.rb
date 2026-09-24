# frozen_string_literal: true

require 'rails_helper'

# Porting Payments, Financial Aid Requests and Applicant Details deleted their app/admin
# registrations and therefore their `legacy_admin_*` route helpers. Pages still served by
# ActiveAdmin that used to link them (the legacy dashboard's payments / financial aid panels, the
# legacy Applications show page's applicant, payment and financial aid links, the Payment Requests
# "Matched payment" link) were repointed to the new admin; rendering them here turns a missed
# helper into a failing spec instead of a production 500. The remaining legacy indexes are
# rendered too.
RSpec.describe 'Legacy ActiveAdmin pages linking Money resources', type: :request do
  let(:user) { create(:user, :with_applicant_detail) }
  let!(:enrollment) { create(:enrollment, :accepted, user: user) }
  let!(:payment) { create(:payment, user: user, camp_year: enrollment.campyear, transaction_status: '2') }
  let!(:financial_aid) { create(:financial_aid, :pending, enrollment: enrollment) }
  let!(:payment_request) { create(:payment_request, user: user, payment: payment, camp_year: enrollment.campyear) }

  before { sign_in create(:admin) }

  it 'renders the legacy dashboard with links into the new admin' do
    get '/legacy_admin'

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to include(admin_payments_path)
    expect(body).to include(admin_payment_path(payment))
    expect(body).to include(admin_financial_aid_requests_path)
    expect(body).to include(admin_financial_aid_request_path(financial_aid))
    expect(body).not_to match(%r{legacy_admin/(payments|financial_aid_requests|applicant_details)})
  end

  it 'renders the legacy applications show page with links into the new admin' do
    get "/legacy_admin/applications/#{enrollment.id}"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to include(admin_applicant_detail_path(user.applicant_detail))
    expect(body).to include(admin_payment_path(payment))
    expect(body).to include(new_admin_payment_path(enrollment_id: enrollment.id))
    expect(body).to include(new_admin_financial_aid_request_path(enrollment_id: enrollment.id))
    expect(body).to include(admin_financial_aid_request_path(financial_aid))
    expect(body).not_to match(%r{legacy_admin/(payments|financial_aid_requests|applicant_details)})
  end

  it 'renders the legacy payment requests index with the matched payment link' do
    get '/legacy_admin/payment_requests'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(admin_payment_path(payment))
  end

  it 'no longer serves the ported resources from ActiveAdmin' do
    %w[payments financial_aid_requests applicant_details].each do |resource|
      get "/legacy_admin/#{resource}"

      expect(response).to have_http_status(:not_found), "/legacy_admin/#{resource} returned #{response.status}"
    end
  end

  # Registrations in app/admin are loaded lazily; load them so the list is built from the source
  # of truth rather than a hand-maintained array.
  ActiveAdmin.application.load!
  legacy_index_paths = ActiveAdmin.application.namespaces[:legacy_admin].resources
                                  .select { |resource| resource.is_a?(ActiveAdmin::Resource) }
                                  .to_h { |resource| [resource.resource_name.to_s, resource.route_collection_path] }

  legacy_index_paths.each do |resource_name, path|
    it "renders the remaining legacy #{resource_name} index (#{path})" do
      get path

      expect(response).to have_http_status(:ok), "#{path} returned #{response.status}"
    end
  end
end
