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
      expect(body).not_to include('New Application')
    end

    it 'never turns URL options smuggled into the query string into off-site links' do
      get admin_applications_path, params: { host: 'evil.example', protocol: 'https', port: 8443, script_name: '/x',
                                             only_path: 'false', sort: 'updated_at', scope: 'all', q: { lastname: 'Zim' } }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('evil.example')
      expect(response.body).not_to include('https://')
      expect(response.body).to include('href="/admin/applications?')
      expect(response.body).to include('direction=asc')
      expect(response.body).to include('q%5Blastname%5D=Zim')
      expect(response.body).to include('scope=withdrawn')
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

    it 'paginates with a configurable page size, clamped to the maximum' do
      3.times { create(:enrollment, :application_complete, user: create(:user, :with_applicant_detail)) }

      get admin_applications_path, params: { limit: 2 }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Showing <span class="font-medium">1</span>–<span class="font-medium">2</span>')
      expect(response.body).to include('of <span class="font-medium">4</span>')
      expect(response.body.scan(/<tr id="enrollment_\d+">/).size).to eq(2)

      get admin_applications_path, params: { limit: 2, page: 2 }
      expect(response.body).to include('Showing <span class="font-medium">3</span>–<span class="font-medium">4</span>')
      expect(response.body).to include('aria-current="page">2</span>')

      get admin_applications_path, params: { limit: 99_999 }
      expect(response.body).to include("of <span class=\"font-medium\">4</span>")
      expect(response.body).to include('Showing <span class="font-medium">1</span>–<span class="font-medium">4</span>')

      get admin_applications_path, params: { limit: 'abc' }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Showing <span class="font-medium">1</span>–<span class="font-medium">4</span>')
    end

    it 'renders pagination links (series, prev/next) when there is more than one page' do
      32.times { create(:enrollment, :application_complete, user: create(:user, :with_applicant_detail)) }

      get admin_applications_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Showing <span class="font-medium">1</span>–<span class="font-medium">30</span>')
      expect(response.body).to include('of <span class="font-medium">33</span>')
      expect(response.body).to include('href="/admin/applications?page=2"')
      expect(response.body).to include('rel="next"')
      expect(response.body).to include('aria-current="page">1</span>')

      get admin_applications_path, params: { page: 2, scope: 'all' }
      expect(response.body).to include('Showing <span class="font-medium">31</span>–<span class="font-medium">33</span>')
      expect(response.body).to match(%r{href="/admin/applications\?(page=1&amp;scope=all|scope=all&amp;page=1)"})
      expect(response.body).to include('rel="prev"')
    end

    it 'ignores non-scalar filter values instead of failing' do
      get admin_applications_path, params: { q: { lastname: ['Zim', 'x'] } }
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('active filter')

      get admin_applications_path, params: { q: { lastname: { nested: 'Zim' } } }
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('active filter')
    end

    it 'shows the SQL-computed balance due that matches PaymentState' do
      accepted = create(:enrollment, :accepted, user: create(:user, :with_applicant_detail))
      create(:session_assignment, :accepted, enrollment: accepted, camp_occurrence: CampOccurrence.active.first)
      expected = PaymentState.new(accepted).balance_due
      expect(expected).to be_positive

      get admin_applications_path, params: { scope: 'all' }
      expect(response.body).to include(helpers_money(expected))

      get admin_applications_path(format: :csv), params: { scope: 'all' }
      csv = CSV.parse(response.body, headers: true)
      row = csv.find { |r| r['email'] == accepted.user.email }
      expect(row['Balance Due']).to eq(helpers_money(expected))
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
      expect(body).to include('enctype="multipart/form-data"')
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

    it 'keeps a status that is not in the standard list (e.g. waitlisted) when the form is submitted unchanged' do
      waitlisted = create(:enrollment, :waitlisted, user: create(:user, :with_applicant_detail))
      create(:session_assignment, enrollment: waitlisted, camp_occurrence: CampOccurrence.active.first)
      create(:course_assignment, enrollment: waitlisted, course: Course.first)

      get edit_admin_application_path(waitlisted)
      expect(response.body).to include('<option selected="selected" value="waitlisted">waitlisted</option>')

      patch admin_application_path(waitlisted), params: { enrollment: { application_status: 'waitlisted', notes: 'still waiting' } }

      expect(response).to redirect_to(admin_application_path(waitlisted))
      expect(waitlisted.reload.application_status).to eq('waitlisted')
      expect(waitlisted.notes).to eq('still waiting')
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

    it 'keeps course assignments when the withdrawal cannot be saved' do
      enrolled = create(:enrollment, :enrolled, user: create(:user, :with_applicant_detail))
      create(:course_assignment, enrollment: enrolled, course: Course.first)

      patch admin_application_path(enrolled), params: { withdraw_enrollment: '1', enrollment: { high_school_name: '' } }

      expect(response).to have_http_status(:unprocessable_content)
      enrolled.reload
      expect(enrolled.application_status).to eq('enrolled')
      expect(enrolled.course_assignments.count).to eq(1)
    end
  end

  describe 'member actions' do
    let(:course) { Course.first }

    it 'places an application on the wait list' do
      post waitlist_admin_application_path(enrollment)

      expect(response).to redirect_to(admin_application_path(enrollment))
      expect(enrollment.reload.application_status).to eq('waitlisted')
      expect(flash[:notice]).to include('placed on waitlist')
    end

    it 'removes an application from the wait list' do
      enrollment.update_columns(application_status: 'waitlisted')

      post remove_from_waitlist_admin_application_path(enrollment)

      expect(response).to redirect_to(admin_application_path(enrollment))
      expect(enrollment.reload.application_status).to eq('application complete')
    end

    it 'withdraws an enrolled application and releases its course assignments' do
      enrolled = create(:enrollment, :enrolled, user: create(:user, :with_applicant_detail))
      create(:course_assignment, enrollment: enrolled, course: course)

      post withdraw_admin_application_path(enrolled)

      expect(response).to redirect_to(admin_application_path(enrolled))
      enrolled.reload
      expect(enrolled.application_status).to eq('withdrawn')
      expect(enrolled.application_status_updated_on).to eq(Date.current)
      expect(enrolled.course_assignments).to be_empty
      expect(flash[:notice]).to include("Course: #{course.title}")
      expect(flash[:notice]).to include("Session: #{course.camp_occurrence.description}")
    end

    it 'reports a plain notice when there was nothing to release' do
      enrolled = create(:enrollment, :enrolled, user: create(:user, :with_applicant_detail))

      post withdraw_admin_application_path(enrolled)

      expect(flash[:notice]).to eq('Enrollment has been withdrawn.')
    end

    it 'emails the financial aid request link' do
      expect do
        post send_finaid_request_email_admin_application_path(enrollment)
      end.to change { ActionMailer::Base.deliveries.size }.by(1)

      expect(response).to redirect_to(admin_application_path(enrollment))
      expect(flash[:notice]).to include('was sent')
    end

    it 'does not perform mutations on GET (routes are POST only)' do
      get "/admin/applications/#{enrollment.id}/waitlist"

      expect(response).not_to have_http_status(:ok)
      expect(enrollment.reload.application_status).to eq('application complete')
    end

    context 'as a signed-in applicant (not an admin)' do
      before do
        sign_out admin
        sign_in user
      end

      it 'refuses every member action and leaves the enrollment untouched' do
        [waitlist_admin_application_path(enrollment), remove_from_waitlist_admin_application_path(enrollment),
         withdraw_admin_application_path(enrollment), send_finaid_request_email_admin_application_path(enrollment)].each do |path|
          post path
          expect(response).to redirect_to(new_admin_session_path)
        end

        expect(enrollment.reload.application_status).to eq('application complete')
        expect(ActionMailer::Base.deliveries).to be_empty
      end

      it 'has no public routes left for these mutations' do
        post "/waitlisted/#{enrollment.id}"
        expect(response).to have_http_status(:not_found)
        post "/withdraw/#{enrollment.id}"
        expect(response).to have_http_status(:not_found)
        post "/remove_from_waitlist/#{enrollment.id}"
        expect(response).to have_http_status(:not_found)
        get "/send_finaid_request_email?enrollment_id=#{enrollment.id}"
        expect(response).to have_http_status(:not_found)

        expect(enrollment.reload.application_status).to eq('application complete')
        expect(ActionMailer::Base.deliveries).to be_empty
      end
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

  def helpers_money(cents)
    ApplicationController.helpers.humanized_money_with_symbol(cents.to_f / 100)
  end

  it 'requires an admin' do
    sign_out admin

    get admin_applications_path

    expect(response).to redirect_to(new_admin_session_path)
  end
end
