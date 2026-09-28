# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin session assignments', type: :request do
  let(:admin) { create(:admin) }
  let(:user) { create(:user, :with_applicant_detail) }
  let(:enrollment) { create(:enrollment, user: user) }
  let(:session) { CampOccurrence.active.first }
  let!(:assignment) { create(:session_assignment, enrollment: enrollment, camp_occurrence: session) }

  before do
    user.applicant_detail.update!(lastname: 'Zimmerman', firstname: 'Ada')
    sign_in admin
  end

  describe 'GET /admin/session_assignments' do
    it 'lists current-year assignments with scopes, filters, batch actions and CSV' do
      get admin_session_assignments_path

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('Current years Session Assignments')
      expect(body).to include('Zimmerman, Ada')
      expect(body).to include(admin_application_path(enrollment))
      expect(body).to include(session.description)
      expect(body).to include('With selected:')
      expect(body).to include('Download CSV')
      expect(body).to include(edit_admin_session_assignment_path(assignment))
      expect(body).to include('name="q[offer_status]"')
    end

    it 'scopes to the current year by default, all and accepted' do
      old_camp = create(:camp_configuration, camp_year: 2019, active: false)
      old_session = create(:camp_occurrence, camp_configuration: old_camp, active: false)
      old_enrollment = create(:enrollment, user: create(:user, :with_applicant_detail))
      old_enrollment.update_columns(campyear: 2019)
      old = create(:session_assignment, enrollment: old_enrollment, camp_occurrence: old_session, offer_status: 'accepted')

      get admin_session_assignments_path
      expect(response.body).to include(edit_admin_session_assignment_path(assignment))
      expect(response.body).not_to include(edit_admin_session_assignment_path(old))

      get admin_session_assignments_path, params: { scope: 'all' }
      expect(response.body).to include(edit_admin_session_assignment_path(old))

      accepted = create(:session_assignment, :accepted, enrollment: create(:enrollment, user: create(:user, :with_applicant_detail)), camp_occurrence: session)
      get admin_session_assignments_path, params: { scope: 'accepted' }
      expect(response.body).to include(edit_admin_session_assignment_path(accepted))
      expect(response.body).not_to include(edit_admin_session_assignment_path(assignment))
    end

    it 'filters by enrollment, session and offer status' do
      other_session = create(:camp_occurrence, camp_configuration: session.camp_configuration, description: 'Session Omega', active: true)
      other = create(:session_assignment, :declined, enrollment: create(:enrollment, user: create(:user, :with_applicant_detail)), camp_occurrence: other_session)

      get admin_session_assignments_path, params: { q: { enrollment_id: enrollment.id } }
      expect(response.body).to include(edit_admin_session_assignment_path(assignment))
      expect(response.body).not_to include(edit_admin_session_assignment_path(other))

      get admin_session_assignments_path, params: { q: { camp_occurrence_id: other_session.id } }
      expect(response.body).to include(edit_admin_session_assignment_path(other))
      expect(response.body).not_to include(edit_admin_session_assignment_path(assignment))

      get admin_session_assignments_path, params: { q: { offer_status: 'declined' } }
      expect(response.body).to include(edit_admin_session_assignment_path(other))
      expect(response.body).not_to include(edit_admin_session_assignment_path(assignment))
    end

    it 'sorts through the joins' do
      %w[enrollment session offer_status nope].each do |key|
        get admin_session_assignments_path, params: { sort: key, direction: 'desc' }
        expect(response).to have_http_status(:ok)
      end
    end

    it 'never turns URL options smuggled into the query string into off-site links' do
      get admin_session_assignments_path, params: { host: 'evil.example', protocol: 'https', port: 8443, script_name: '/x',
                                                    only_path: 'false', sort: 'session', scope: 'all', q: { offer_status: 'accepted' } }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('evil.example')
      expect(response.body).not_to include('https://')
      expect(response.body).to include('href="/admin/session_assignments?')
      expect(response.body).to include('q%5Boffer_status%5D=accepted')
      expect(response.body).to include('scope=accepted')
    end

    it 'paginates 30 rows per page' do
      32.times { create(:session_assignment, enrollment: create(:enrollment, user: create(:user, :with_applicant_detail)), camp_occurrence: session) }

      get admin_session_assignments_path
      expect(response.body.scan('<tr id="session_assignment_').size).to eq(30)
      expect(response.body).to include('rel="next"')

      get admin_session_assignments_path, params: { page: 2 }
      expect(response.body).to include('Showing <span class="font-medium">31</span>–<span class="font-medium">33</span>')
    end

    it 'exports the ActiveAdmin CSV columns' do
      get admin_session_assignments_path(format: :csv)

      expect(response.media_type).to eq('text/csv')
      csv = CSV.parse(response.body)
      expect(csv.first).to eq(%w[Name email Session])
      expect(csv.second).to eq(['Zimmerman, Ada', user.email, session.display_name])
    end
  end

  describe 'GET /admin/session_assignments/:id' do
    it 'renders the attributes and comments' do
      get admin_session_assignment_path(assignment)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Zimmerman, Ada')
      expect(response.body).to include(admin_application_path(enrollment))
      expect(response.body).to include(session.description)
      expect(response.body).to include('resource_type" value="SessionAssignment"')
    end

    it 'accepts admin comments' do
      post admin_comments_path, params: { resource_type: 'SessionAssignment', resource_id: assignment.id, admin_comment: { body: 'Offer sent' } },
                                headers: { 'HTTP_REFERER' => admin_session_assignment_path(assignment) }

      expect(response).to redirect_to(admin_session_assignment_path(assignment))
      expect(assignment.admin_comments.pluck(:body)).to eq(['Offer sent'])
    end
  end

  describe 'new/create' do
    it 'renders the form with accepted/declined offer statuses' do
      get new_admin_session_assignment_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Zimmerman, Ada - #{user.email}")
      expect(response.body).to include('<option value="accepted">accepted</option>')
      expect(response.body).to include('<option value="declined">declined</option>')
    end

    it 'creates an assignment' do
      other = create(:enrollment, user: create(:user, :with_applicant_detail))

      expect do
        post admin_session_assignments_path, params: { session_assignment: { enrollment_id: other.id, camp_occurrence_id: session.id, offer_status: '' } }
      end.to change(SessionAssignment, :count).by(1)
      expect(SessionAssignment.last.offer_status).to be_blank
      expect(response).to redirect_to(admin_session_assignment_path(SessionAssignment.last))
    end

    it 're-renders with errors when invalid' do
      post admin_session_assignments_path, params: { session_assignment: { enrollment_id: '', camp_occurrence_id: session.id } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('Enrollment must exist')
    end
  end

  describe 'edit/update' do
    it 'keeps a non-standard persisted offer status selectable' do
      assignment.update_columns(offer_status: 'offered')

      get edit_admin_session_assignment_path(assignment)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<option selected="selected" value="offered">offered</option>')
    end

    it 'updates the offer status' do
      patch admin_session_assignment_path(assignment), params: { session_assignment: { offer_status: 'accepted' } }

      expect(response).to redirect_to(admin_session_assignment_path(assignment))
      expect(assignment.reload.offer_status).to eq('accepted')
    end
  end

  describe 'destroy and batch' do
    it 'destroys the assignment' do
      expect { delete admin_session_assignment_path(assignment) }.to change(SessionAssignment, :count).by(-1)
      expect(response).to redirect_to(admin_session_assignments_path)
    end

    it 'destroys the selected assignments' do
      expect { post batch_admin_session_assignments_path, params: { batch_action: 'destroy', ids: [assignment.id] } }
        .to change(SessionAssignment, :count).by(-1)
    end
  end

  it 'requires an admin' do
    sign_out admin
    get admin_session_assignments_path
    expect(response).to redirect_to(new_admin_session_path)
  end
end
