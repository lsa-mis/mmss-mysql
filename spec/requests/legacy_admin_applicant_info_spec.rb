# frozen_string_literal: true

require 'rails_helper'

# Porting the Applicant Info resources deleted their app/admin registrations and therefore their
# `legacy_admin_*` route helpers. Pages still served by ActiveAdmin that used to link them (the
# legacy Applications show page: rejection action item, session/course assignment, recommendation
# and recupload tables) were repointed to the new admin; rendering them here turns a missed helper
# into a failing spec instead of a production 500. Every remaining legacy index is rendered by
# spec/requests/legacy_admin_spec.rb.
RSpec.describe 'Legacy ActiveAdmin pages linking Applicant Info resources', type: :request do
  let(:user) { create(:user, :with_applicant_detail) }
  let!(:enrollment) { create(:enrollment, :application_complete, user: user) }

  before do
    session = CampOccurrence.active.first
    create(:session_assignment, enrollment: enrollment, camp_occurrence: session)
    create(:course_assignment, enrollment: enrollment, course: Course.where(camp_occurrence: session).first)
    create(:recupload, recommendation: create(:recommendation, enrollment: enrollment))
    sign_in create(:admin)
  end

  it 'renders the legacy applications show page with links into the new admin' do
    get "/legacy_admin/applications/#{enrollment.id}"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to include(new_admin_rejection_path(enrollment_id: enrollment.id))
    expect(body).to include(admin_session_assignment_path(enrollment.session_assignments.first))
    expect(body).to include(admin_course_assignment_path(enrollment.course_assignments.first))
    expect(body).to include(admin_recommendation_path(enrollment.recommendation))
    expect(body).to include(admin_recupload_path(enrollment.recommendation.recupload))
    expect(body).not_to match(%r{legacy_admin/(rejections|session_assignments|course_assignments|recommendations|recuploads)})
  end

  it 'renders the legacy applications index' do
    get '/legacy_admin/applications'

    expect(response).to have_http_status(:ok)
  end

  it 'no longer serves the ported resources from ActiveAdmin' do
    %w[course_assignments course_preferences session_selections session_assignments applicant_activities
       recommendations recuploads rejections travels payment_requests nelnet_callback_logs].each do |resource|
      get "/legacy_admin/#{resource}"

      expect(response).to have_http_status(:not_found), "/legacy_admin/#{resource} returned #{response.status}"
    end
  end
end
