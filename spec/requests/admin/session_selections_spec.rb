# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin session selections', type: :request do
  let(:admin) { create(:admin) }
  let(:user) { create(:user, :with_applicant_detail) }
  let(:enrollment) { create(:enrollment, user: user) }
  let(:session) { CampOccurrence.active.first }
  # The enrollment factory already registers the applicant for every active session.
  let!(:selection) { enrollment.session_activities.find_by!(camp_occurrence: session) }

  before do
    user.applicant_detail.update!(lastname: 'Zimmerman', firstname: 'Ada')
    sign_in admin
  end

  describe 'GET /admin/session_selections' do
    it 'lists selections with applicant links, the session, filters and batch actions' do
      get admin_session_selections_path

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('Session Selection')
      expect(body).to include('Zimmerman, Ada')
      expect(body).to include(admin_application_path(enrollment))
      expect(body).to include(session.description)
      expect(body).to include('With selected:')
      expect(body).to include('Download CSV')
      expect(body).to include(edit_admin_session_selection_path(selection))
      expect(body).to include('name="q[enrollment_id]"')
      expect(body).to include('name="q[camp_occurrence_id]"')
    end

    it 'filters by enrollment and session' do
      other_session = create(:camp_occurrence, camp_configuration: session.camp_configuration, description: 'Session Omega', active: true)
      other = create(:session_activity, enrollment: create(:enrollment, user: create(:user, :with_applicant_detail)), camp_occurrence: other_session)

      get admin_session_selections_path, params: { q: { enrollment_id: enrollment.id } }
      expect(response.body).to include(edit_admin_session_selection_path(selection))
      expect(response.body).not_to include(edit_admin_session_selection_path(other))

      get admin_session_selections_path, params: { q: { camp_occurrence_id: other_session.id } }
      expect(response.body).to include(edit_admin_session_selection_path(other))
      expect(response.body).not_to include(edit_admin_session_selection_path(selection))
    end

    it 'sorts through the joins' do
      %w[enrollment session created_at nope].each do |key|
        get admin_session_selections_path, params: { sort: key, direction: 'desc' }
        expect(response).to have_http_status(:ok)
      end
    end

    it 'never turns URL options smuggled into the query string into off-site links' do
      get admin_session_selections_path, params: { host: 'evil.example', protocol: 'https', port: 8443, script_name: '/x',
                                                   only_path: 'false', sort: 'session', q: { camp_occurrence_id: session.id } }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('evil.example')
      expect(response.body).not_to include('https://')
      expect(response.body).to include('href="/admin/session_selections?')
      expect(response.body).to include("q%5Bcamp_occurrence_id%5D=#{session.id}")
    end

    it 'paginates 30 rows per page' do
      # Each enrollment registers for every active session, so 32 more enrollments give 33 rows.
      32.times { create(:enrollment, user: create(:user, :with_applicant_detail)) }

      get admin_session_selections_path
      expect(response.body.scan('<tr id="session_activity_').size).to eq(30)
      expect(response.body).to include('rel="next"')

      get admin_session_selections_path, params: { page: 2 }
      expect(response.body).to include('Showing <span class="font-medium">31</span>–<span class="font-medium">33</span>')
    end

    it 'exports CSV' do
      get admin_session_selections_path(format: :csv)

      expect(response.media_type).to eq('text/csv')
      csv = CSV.parse(response.body)
      expect(csv.first).to eq(['Id', 'Name', 'email', 'Session', 'Created at', 'Updated at'])
      expect(csv.second[1..3]).to eq(['Zimmerman, Ada', user.email, session.display_name])
    end
  end

  describe 'GET /admin/session_selections/:id' do
    it 'renders the applicant email link, the session and comments' do
      get admin_session_selection_path(selection)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(user.email)
      expect(response.body).to include(admin_application_path(enrollment))
      expect(response.body).to include(session.description)
      expect(response.body).to include('resource_type" value="SessionActivity"')
    end

    it 'accepts admin comments' do
      post admin_comments_path, params: { resource_type: 'SessionActivity', resource_id: selection.id, admin_comment: { body: 'Confirmed by phone' } },
                                headers: { 'HTTP_REFERER' => admin_session_selection_path(selection) }

      expect(response).to redirect_to(admin_session_selection_path(selection))
      expect(selection.admin_comments.pluck(:body)).to eq(['Confirmed by phone'])
    end
  end

  describe 'new/create' do
    it 'renders the form' do
      get new_admin_session_selection_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Zimmerman, Ada - #{user.email}")
      expect(response.body).to include('name="session_activity[camp_occurrence_id]"')
    end

    it 'creates a selection' do
      other_session = create(:camp_occurrence, camp_configuration: session.camp_configuration, description: 'Session Omega', active: true)

      expect do
        post admin_session_selections_path, params: { session_activity: { enrollment_id: enrollment.id, camp_occurrence_id: other_session.id } }
      end.to change(SessionActivity, :count).by(1)
      expect(response).to redirect_to(admin_session_selection_path(SessionActivity.last))
    end

    it 're-renders with errors when invalid' do
      post admin_session_selections_path, params: { session_activity: { enrollment_id: enrollment.id, camp_occurrence_id: '' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('Camp occurrence must exist')
    end
  end

  describe 'edit/update' do
    it 'keeps an inactive persisted session selectable' do
      inactive = create(:camp_occurrence, camp_configuration: session.camp_configuration, description: 'Retired Session', active: false)
      selection.update!(camp_occurrence: inactive)

      get edit_admin_session_selection_path(selection)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Retired Session')
    end

    it 'updates the selection' do
      other_session = create(:camp_occurrence, camp_configuration: session.camp_configuration, description: 'Session Omega', active: true)

      patch admin_session_selection_path(selection), params: { session_activity: { camp_occurrence_id: other_session.id } }

      expect(response).to redirect_to(admin_session_selection_path(selection))
      expect(selection.reload.camp_occurrence).to eq(other_session)
    end
  end

  describe 'destroy and batch' do
    it 'destroys the selection' do
      expect { delete admin_session_selection_path(selection) }.to change(SessionActivity, :count).by(-1)
      expect(response).to redirect_to(admin_session_selections_path)
    end

    it 'destroys the selected records' do
      expect { post batch_admin_session_selections_path, params: { batch_action: 'destroy', ids: [selection.id] } }
        .to change(SessionActivity, :count).by(-1)
    end
  end

  it 'requires an admin' do
    sign_out admin
    get admin_session_selections_path
    expect(response).to redirect_to(new_admin_session_path)
  end
end
