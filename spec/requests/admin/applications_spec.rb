# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin applications', type: :request do
  let(:admin) { create(:admin) }
  let(:user) { create(:user, :with_applicant_detail) }
  let!(:enrollment) { create(:enrollment, :application_complete, user: user, notes: 'Needs transcript follow-up') }

  before do
    user.applicant_detail.update!(lastname: 'Zimmerman', firstname: 'Ada')
    sign_in admin
  end

  describe 'GET /admin/applications' do
    it 'lists current-year applications with scopes, filters and actions' do
      get admin_applications_path

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('Zimmerman, Ada')
      expect(body).to include(user.email)
      expect(body).to include('Current years Applications')
      expect(body).to include('Last Name (Starts with)')
      expect(body).to include('With selected:')
      expect(body).to include(edit_admin_application_path(enrollment))
      expect(body).to include('Download CSV')
      expect(body).to include('Balance Due')
    end

    it 'filters by applicant last name (starts with)' do
      other = create(:enrollment, :application_complete, user: create(:user, :with_applicant_detail))
      other.applicant_detail.update!(lastname: 'Anderson')

      get admin_applications_path, params: { q: { lastname: 'Zim' } }

      expect(response.body).to include('Zimmerman')
      expect(response.body).not_to include('Anderson')
      expect(response.body).to include('1 active filter')
    end

    it 'filters by status select, boolean and date range' do
      withdrawn = create(:enrollment, :withdrawn, user: create(:user, :with_applicant_detail), international: true,
                                                   application_deadline: Date.new(2030, 1, 15))
      withdrawn.applicant_detail.update!(lastname: 'Withdrawnson')

      get admin_applications_path, params: { scope: 'all', q: { application_status: 'withdrawn' } }
      expect(response.body).to include('Withdrawnson')
      expect(response.body).not_to include('Zimmerman')

      get admin_applications_path, params: { scope: 'all', q: { international: 'true' } }
      expect(response.body).to include('Withdrawnson')
      expect(response.body).not_to include('Zimmerman')

      get admin_applications_path, params: { scope: 'all', q: { application_deadline_from: '2030-01-01', application_deadline_to: '2030-01-31' } }
      expect(response.body).to include('Withdrawnson')
      expect(response.body).not_to include('Zimmerman')
    end

    it 'switches scopes and shows counts' do
      create(:enrollment, :withdrawn, user: create(:user, :with_applicant_detail))

      get admin_applications_path, params: { scope: 'withdrawn' }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('Zimmerman')
      expect(response.body).to include('admin-tab-active')
    end

    it 'sorts by an allowed column and ignores unknown ones' do
      get admin_applications_path, params: { sort: 'applicant', direction: 'asc' }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('direction=desc')

      get admin_applications_path, params: { sort: 'drop table', direction: 'asc' }
      expect(response).to have_http_status(:ok)
    end

    it 'paginates with a configurable page size' do
      get admin_applications_path, params: { limit: 1 }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Showing')
    end

    it 'exports the current scope as CSV with the ActiveAdmin column set' do
      get admin_applications_path(format: :csv), params: { scope: 'all' }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/csv')
      expect(response.headers['Content-Disposition']).to include('MMSS-applications-')
      csv = CSV.parse(response.body)
      expect(csv.first).to eq(
        ['Updated at', 'Name', 'email', 'Transcript', 'Offer status', 'Application deadline', 'Application status',
         'Application status updated on', 'International', 'Year in school', 'Anticipated graduation year',
         'Room mate request', 'Notes', 'Partner program', 'Camp doc form completed', 'Balance Due', 'Camp Year']
      )
      row = csv.second
      expect(row[1]).to eq('Zimmerman, Ada')
      expect(row[2]).to eq(user.email)
      expect(row[3]).to eq('uploaded')
      expect(row[6]).to eq('application complete')
      expect(row.last).to eq(enrollment.campyear.to_s)
    end
  end

  describe 'GET /admin/applications/:id' do
    it 'renders the application, its panels, details sidebar and comments' do
      create(:session_assignment, enrollment: enrollment, camp_occurrence: CampOccurrence.active.first, offer_status: 'accepted')

      get admin_application_path(enrollment)

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include("Application ##{enrollment.id}")
      expect(body).to include('Zimmerman, Ada')
      %w[Session\ Assignment Course\ Assignment Activities\ /\ Services Finances Recommendation Details Comments].each do |panel|
        expect(body).to include(panel)
      end
      expect(body).to include('Place on Wait List')
      expect(body).to include('Reject Applicant')
      expect(body).to include('Add a comment')
      expect(body).to include(enrollment.high_school_name)
    end
  end

  describe 'GET /admin/applications/:id/edit' do
    it 'renders the form with nested assignment fields and status block' do
      create(:session_assignment, enrollment: enrollment, camp_occurrence: CampOccurrence.active.first)
      create(:course_assignment, enrollment: enrollment, course: Course.first)

      get edit_admin_application_path(enrollment)

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('name="enrollment[high_school_country]"')
      expect(body).to include('enrollment[session_assignments_attributes]')
      expect(body).to include('enrollment[course_assignments_attributes]')
      expect(body).to include('NEW_RECORD')
      expect(body).to include('application_application_status')
      expect(body).to include('Withdraw Enrollment')
    end
  end

  describe 'PATCH /admin/applications/:id' do
    it 'updates attributes and redirects to the show page' do
      patch admin_application_path(enrollment), params: { enrollment: { notes: 'Updated by admin', partner_program: 'Partner X' } }

      expect(response).to redirect_to(admin_application_path(enrollment))
      expect(enrollment.reload.notes).to eq('Updated by admin')
      expect(enrollment.partner_program).to eq('Partner X')
      follow_redirect!
      expect(response.body).to include('Application was successfully updated.')
    end

    it 're-renders the form with errors when invalid' do
      patch admin_application_path(enrollment), params: { enrollment: { high_school_name: '' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('1 error prevented this record from being saved')
      expect(CGI.unescapeHTML(response.body)).to include("High school name can't be blank")
    end

    it 'withdraws the enrollment, deleting course assignments, when the Withdraw button is used' do
      enrolled = create(:enrollment, :enrolled, user: create(:user, :with_applicant_detail))
      course = Course.first
      create(:course_assignment, enrollment: enrolled, course: course)

      patch admin_application_path(enrolled), params: { withdraw_enrollment: '1', enrollment: { notes: 'bye' } }

      expect(response).to redirect_to(admin_application_path(enrolled))
      enrolled.reload
      expect(enrolled.application_status).to eq('withdrawn')
      expect(enrolled.application_status_updated_on).to eq(Date.current)
      expect(enrolled.course_assignments).to be_empty
      expect(flash[:notice]).to include('Enrollment has been withdrawn')
      expect(flash[:notice]).to include("Course: #{course.title}")
    end
  end

  describe 'POST /admin/applications' do
    it 'creates an application for a user' do
      new_user = create(:user, :with_applicant_detail)
      transcript = Rack::Test::UploadedFile.new(Rails.root.join('spec/files/test.pdf'), 'application/pdf')
      attributes = enrollment.attributes.slice(
        'international', 'high_school_name', 'high_school_address1', 'high_school_city', 'high_school_state',
        'high_school_postalcode', 'high_school_country', 'year_in_school', 'anticipated_graduation_year', 'personal_statement', 'campyear'
      ).merge('user_id' => new_user.id, 'transcript' => transcript)

      # Admin-created applications still need the applicant's own session/course registrations.
      allow_any_instance_of(Enrollment).to receive(:session_registration_ids).and_return([1])
      allow_any_instance_of(Enrollment).to receive(:course_registration_ids).and_return([1])

      expect do
        post admin_applications_path, params: { enrollment: attributes }
      end.to change(Enrollment, :count).by(1)

      expect(response).to redirect_to(admin_application_path(Enrollment.last))
    end
  end

  describe 'DELETE /admin/applications/:id' do
    it 'destroys the application' do
      expect { delete admin_application_path(enrollment) }.to change(Enrollment, :count).by(-1)
      expect(response).to redirect_to(admin_applications_path)
    end
  end

  describe 'POST /admin/applications/batch' do
    it 'destroys the selected applications' do
      other = create(:enrollment, user: create(:user, :with_applicant_detail))

      expect do
        post batch_admin_applications_path, params: { batch_action: 'destroy', ids: [enrollment.id, other.id] }
      end.to change(Enrollment, :count).by(-2)

      expect(response).to redirect_to(admin_applications_path)
      expect(flash[:notice]).to include('Deleted 2')
    end

    it 'rejects unknown batch actions' do
      post batch_admin_applications_path, params: { batch_action: 'nuke', ids: [enrollment.id] }

      expect(response).to redirect_to(admin_applications_path)
      expect(flash[:alert]).to include('Unknown batch action')
      expect(Enrollment.exists?(enrollment.id)).to be(true)
    end
  end

  it 'requires an admin' do
    sign_out admin

    get admin_applications_path

    expect(response).to redirect_to(new_admin_session_path)
  end
end
