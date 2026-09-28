# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin course preferences', type: :request do
  let(:admin) { create(:admin) }
  let(:user) { create(:user, :with_applicant_detail) }
  let(:enrollment) { create(:enrollment, user: user) }
  let(:session) { CampOccurrence.active.first }
  let(:course) { create(:course, camp_occurrence: session, title: 'Number Theory') }
  let!(:preference) { create(:course_preference, enrollment: enrollment, course: course, ranking: 1) }

  before do
    user.applicant_detail.update!(lastname: 'Zimmerman', firstname: 'Ada')
    sign_in admin
  end

  describe 'GET /admin/course_preferences' do
    it 'lists preferences with session, course, ranking, filters and batch actions' do
      get admin_course_preferences_path

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('Zimmerman, Ada')
      expect(body).to include(admin_application_path(enrollment))
      expect(body).to include('Number Theory')
      expect(body).to include(session.description)
      expect(body).to include('With selected:')
      expect(body).to include('Download CSV')
      expect(body).to include(edit_admin_course_preference_path(preference))
      expect(body).to include('name="q[enrollment_id]"')
      expect(body).to include('name="q[course_id]"')
    end

    it 'filters by enrollment and course' do
      other_course = create(:course, camp_occurrence: session, title: 'Topology')
      # The enrollment factory registers the applicant for every active course.
      other_enrollment = create(:enrollment, user: create(:user, :with_applicant_detail))
      other = other_enrollment.course_preferences.find_by!(course: other_course)

      get admin_course_preferences_path, params: { q: { enrollment_id: enrollment.id } }
      expect(response.body).to include(edit_admin_course_preference_path(preference))
      expect(response.body).not_to include(edit_admin_course_preference_path(other))

      get admin_course_preferences_path, params: { q: { course_id: other_course.id } }
      expect(response.body).to include(edit_admin_course_preference_path(other))
      expect(response.body).not_to include(edit_admin_course_preference_path(preference))
    end

    it 'sorts through the joins and ignores unknown keys' do
      %w[enrollment session course ranking nope].each do |key|
        get admin_course_preferences_path, params: { sort: key, direction: 'desc' }
        expect(response).to have_http_status(:ok)
      end
    end

    it 'never turns URL options smuggled into the query string into off-site links' do
      get admin_course_preferences_path, params: { host: 'evil.example', protocol: 'https', port: 8443, script_name: '/x',
                                                   only_path: 'false', sort: 'ranking', q: { course_id: course.id } }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('evil.example')
      expect(response.body).not_to include('https://')
      expect(response.body).to include('href="/admin/course_preferences?')
      expect(response.body).to include("q%5Bcourse_id%5D=#{course.id}")
    end

    it 'paginates 30 rows per page' do
      # Every enrollment registers for all active courses, so 16 more enrollments add >= 32 rows.
      16.times { create(:enrollment, user: create(:user, :with_applicant_detail)) }

      get admin_course_preferences_path
      expect(response.body.scan('<tr id="course_preference_').size).to eq(30)
      expect(response.body).to include('rel="next"')

      get admin_course_preferences_path, params: { page: 2 }
      expect(response.body).to include('Showing <span class="font-medium">31</span>')
      expect(response.body).to include('rel="prev"')
    end

    it 'exports CSV' do
      get admin_course_preferences_path(format: :csv)

      expect(response.media_type).to eq('text/csv')
      csv = CSV.parse(response.body)
      expect(csv.first).to eq(['Id', 'Name', 'email', 'Session', 'Course', 'Ranking', 'Created at', 'Updated at'])
      expect(csv.second[1..5]).to eq(['Zimmerman, Ada', user.email, session.description, 'Number Theory', '1'])
    end
  end

  describe 'GET /admin/course_preferences/:id' do
    it 'renders the attributes' do
      get admin_course_preference_path(preference)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Zimmerman, Ada')
      expect(response.body).to include(admin_application_path(enrollment))
      expect(response.body).to include('Number Theory')
    end
  end

  describe 'new/create' do
    it 'renders the form with a 1..12 ranking select' do
      get new_admin_course_preference_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Zimmerman, Ada - #{user.email}")
      expect(response.body).to include('<option value="12">12</option>')
    end

    it 'creates a preference' do
      other_course = create(:course, camp_occurrence: session, title: 'Topology')

      expect do
        post admin_course_preferences_path, params: { course_preference: { enrollment_id: enrollment.id, course_id: other_course.id, ranking: 2 } }
      end.to change(CoursePreference, :count).by(1)
      expect(response).to redirect_to(admin_course_preference_path(CoursePreference.last))
    end

    it 're-renders with errors when the course is already ranked' do
      post admin_course_preferences_path, params: { course_preference: { enrollment_id: enrollment.id, course_id: course.id, ranking: 2 } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('Course has already been taken')
    end
  end

  describe 'edit/update' do
    it 'renders the edit form with the persisted values selected' do
      get edit_admin_course_preference_path(preference)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(<option selected="selected" value="#{course.id}">))
      expect(response.body).to include('<option selected="selected" value="1">1</option>')
    end

    it 'updates the ranking' do
      patch admin_course_preference_path(preference), params: { course_preference: { ranking: 2 } }

      expect(response).to redirect_to(admin_course_preference_path(preference))
      expect(preference.reload.ranking).to eq(2)
    end

    it 're-renders with errors when invalid' do
      patch admin_course_preference_path(preference), params: { course_preference: { ranking: 0 } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('Ranking must be greater than or equal to 1')
    end
  end

  describe 'destroy and batch' do
    it 'destroys the preference' do
      expect { delete admin_course_preference_path(preference) }.to change(CoursePreference, :count).by(-1)
      expect(response).to redirect_to(admin_course_preferences_path)
    end

    it 'destroys the selected preferences' do
      expect { post batch_admin_course_preferences_path, params: { batch_action: 'destroy', ids: [preference.id] } }
        .to change(CoursePreference, :count).by(-1)
    end
  end

  it 'requires an admin' do
    sign_out admin
    get admin_course_preferences_path
    expect(response).to redirect_to(new_admin_session_path)
  end
end
