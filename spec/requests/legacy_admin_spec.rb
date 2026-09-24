# frozen_string_literal: true

require 'rails_helper'

# Every resource still registered with ActiveAdmin (served at /legacy_admin) must keep rendering
# while the new admin is built up one menu group at a time. Legacy pages link to each other with
# `legacy_admin_*_path` helpers; porting a resource deletes its app/admin file and therefore the
# helper, which only surfaces at render time. Rendering each legacy index (and the pages that link
# a ported resource) here turns that into a failing spec instead of a production 500.
RSpec.describe 'Legacy ActiveAdmin pages', type: :request do
  let(:camp_configuration) { create(:camp_configuration, :current_year) }
  let(:session) { create(:camp_occurrence, camp_configuration: camp_configuration, active: true) }
  let(:user) { create(:user, :with_applicant_detail) }

  before do
    create(:course, camp_occurrence: session)
    create(:enrollment, :application_complete, user: user)
    sign_in create(:admin)
  end

  # Registrations in app/admin are loaded lazily; load them so the list is built from the source
  # of truth rather than a hand-maintained array.
  ActiveAdmin.application.load!
  legacy_index_paths = ActiveAdmin.application.namespaces[:legacy_admin].resources
                                  .select { |resource| resource.is_a?(ActiveAdmin::Resource) }
                                  .to_h { |resource| [resource.resource_name.to_s, resource.route_collection_path] }

  legacy_index_paths.each do |resource_name, path|
    it "renders the #{resource_name} index (#{path})" do
      get path

      expect(response).to have_http_status(:ok), "#{path} returned #{response.status}"
    end
  end

  it 'renders the applications index, which links applicants to the new admin users pages' do
    get '/legacy_admin/applications'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(admin_user_path(user))
    expect(response.body).not_to include('legacy_admin/users')
  end

  it 'renders the dashboard' do
    get legacy_admin_root_path

    expect(response).to have_http_status(:ok)
  end
end
