# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin applicant activities', type: :request do
  let(:admin) { create(:admin) }
  let(:user) { create(:user, :with_applicant_detail) }
  let(:enrollment) { create(:enrollment, user: user) }
  let(:session) { CampOccurrence.active.first }
  let(:activity) { create(:activity, camp_occurrence: session, description: 'Residential Stay') }
  let!(:record) { create(:enrollment_activity, enrollment: enrollment, activity: activity) }

  before do
    user.applicant_detail.update!(lastname: 'Zimmerman', firstname: 'Ada')
    sign_in admin
  end

  describe 'GET /admin/applicant_activities' do
    it 'lists activities with applicant links, filters, batch actions and CSV' do
      get admin_applicant_activities_path

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('Applicant Activities')
      expect(body).to include('Zimmerman, Ada')
      expect(body).to include(admin_application_path(enrollment))
      expect(body).to include('Residential Stay')
      expect(body).to include(session.description)
      expect(body).to include('With selected:')
      expect(body).to include('Download CSV')
      expect(body).to include(edit_admin_applicant_activity_path(record))
      expect(body).to include('name="q[activity_id]"')
    end

    it 'filters by enrollment and activity' do
      other_activity = create(:activity, camp_occurrence: session, description: 'Field Trip')
      other = create(:enrollment_activity, enrollment: create(:enrollment, user: create(:user, :with_applicant_detail)), activity: other_activity)

      get admin_applicant_activities_path, params: { q: { enrollment_id: enrollment.id } }
      expect(response.body).to include(edit_admin_applicant_activity_path(record))
      expect(response.body).not_to include(edit_admin_applicant_activity_path(other))

      get admin_applicant_activities_path, params: { q: { activity_id: other_activity.id } }
      expect(response.body).to include(edit_admin_applicant_activity_path(other))
      expect(response.body).not_to include(edit_admin_applicant_activity_path(record))
    end

    it 'sorts through the joins' do
      %w[enrollment activity session nope].each do |key|
        get admin_applicant_activities_path, params: { sort: key, direction: 'desc' }
        expect(response).to have_http_status(:ok)
      end
    end

    it 'never turns URL options smuggled into the query string into off-site links' do
      get admin_applicant_activities_path, params: { host: 'evil.example', protocol: 'https', port: 8443, script_name: '/x',
                                                     only_path: 'false', sort: 'activity', q: { activity_id: activity.id } }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('evil.example')
      expect(response.body).not_to include('https://')
      expect(response.body).to include('href="/admin/applicant_activities?')
      expect(response.body).to include("q%5Bactivity_id%5D=#{activity.id}")
    end

    it 'paginates 30 rows per page' do
      32.times { create(:enrollment_activity, enrollment: create(:enrollment, user: create(:user, :with_applicant_detail)), activity: activity) }

      get admin_applicant_activities_path
      expect(response.body.scan('<tr id="enrollment_activity_').size).to eq(30)
      expect(response.body).to include('rel="next"')

      get admin_applicant_activities_path, params: { page: 2 }
      expect(response.body).to include('Showing <span class="font-medium">31</span>–<span class="font-medium">33</span>')
    end

    it 'exports the ActiveAdmin CSV columns' do
      get admin_applicant_activities_path(format: :csv)

      expect(response.media_type).to eq('text/csv')
      csv = CSV.parse(response.body)
      expect(csv.first).to eq(%w[Name email Activity Session])
      expect(csv.second).to eq(['Zimmerman, Ada', user.email, 'Residential Stay', session.display_name])
    end
  end

  describe 'GET /admin/applicant_activities/:id' do
    it 'renders the attributes' do
      get admin_applicant_activity_path(record)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Zimmerman, Ada')
      expect(response.body).to include(admin_application_path(enrollment))
      expect(response.body).to include('Residential Stay')
    end
  end

  describe 'new/create' do
    it 'renders the form with active-session activities' do
      get new_admin_applicant_activity_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Zimmerman, Ada - #{user.email}")
      expect(response.body).to include('Residential Stay')
      expect(response.body).to include('name="enrollment_activity[activity_id]"')
    end

    it 'creates a record' do
      other = create(:enrollment, user: create(:user, :with_applicant_detail))

      expect do
        post admin_applicant_activities_path, params: { enrollment_activity: { enrollment_id: other.id, activity_id: activity.id } }
      end.to change(EnrollmentActivity, :count).by(1)
      expect(response).to redirect_to(admin_applicant_activity_path(EnrollmentActivity.last))
    end

    it 're-renders with errors when invalid' do
      post admin_applicant_activities_path, params: { enrollment_activity: { enrollment_id: enrollment.id, activity_id: '' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(CGI.unescapeHTML(response.body)).to include("Activity can't be blank")
    end
  end

  describe 'edit/update' do
    it 'keeps an activity from an inactive session selectable' do
      inactive = create(:camp_occurrence, camp_configuration: session.camp_configuration, active: false)
      old_activity = create(:activity, camp_occurrence: inactive, description: 'Retired Activity')
      record.update!(activity: old_activity)

      get edit_admin_applicant_activity_path(record)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Retired Activity')
    end

    it 'updates the record' do
      other_activity = create(:activity, camp_occurrence: session, description: 'Field Trip')

      patch admin_applicant_activity_path(record), params: { enrollment_activity: { activity_id: other_activity.id } }

      expect(response).to redirect_to(admin_applicant_activity_path(record))
      expect(record.reload.activity).to eq(other_activity)
    end
  end

  describe 'destroy and batch' do
    it 'destroys the record' do
      expect { delete admin_applicant_activity_path(record) }.to change(EnrollmentActivity, :count).by(-1)
      expect(response).to redirect_to(admin_applicant_activities_path)
    end

    it 'destroys the selected records' do
      expect { post batch_admin_applicant_activities_path, params: { batch_action: 'destroy', ids: [record.id] } }
        .to change(EnrollmentActivity, :count).by(-1)
    end
  end

  it 'requires an admin' do
    sign_out admin
    get admin_applicant_activities_path
    expect(response).to redirect_to(new_admin_session_path)
  end
end
