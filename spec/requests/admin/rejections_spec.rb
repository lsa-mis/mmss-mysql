# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin rejections', type: :request do
  let(:admin) { create(:admin) }
  let(:user) { create(:user, :with_applicant_detail) }
  let(:enrollment) { create(:enrollment, :application_complete, user: user) }
  let!(:rejection) { create(:rejection, enrollment: enrollment, reason: 'Incomplete transcript') }

  before do
    user.applicant_detail.update!(lastname: 'Zimmerman', firstname: 'Ada')
    ActionMailer::Base.deliveries.clear
    sign_in admin
  end

  describe 'GET /admin/rejections' do
    it 'lists rejections with applicant links, the reason, filters and batch actions' do
      get admin_rejections_path

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('Zimmerman, Ada')
      expect(body).to include(admin_application_path(enrollment))
      expect(body).to include('Incomplete transcript')
      expect(body).to include('With selected:')
      expect(body).to include('Download CSV')
      expect(body).to include(edit_admin_rejection_path(rejection))
      expect(body).to include('name="q[enrollment_id]"')
    end

    it 'filters by enrollment and date' do
      other = create(:rejection, enrollment: create(:enrollment, :application_complete, user: create(:user, :with_applicant_detail)))

      get admin_rejections_path, params: { q: { enrollment_id: enrollment.id } }
      expect(response.body).to include(edit_admin_rejection_path(rejection))
      expect(response.body).not_to include(edit_admin_rejection_path(other))

      get admin_rejections_path, params: { q: { created_at_to: '2000-01-01' } }
      expect(response.body).not_to include(edit_admin_rejection_path(rejection))
    end

    it 'sorts by applicant through the join' do
      %w[enrollment id nope].each do |key|
        get admin_rejections_path, params: { sort: key, direction: 'desc' }
        expect(response).to have_http_status(:ok)
      end
    end

    it 'never turns URL options smuggled into the query string into off-site links' do
      get admin_rejections_path, params: { host: 'evil.example', protocol: 'https', port: 8443, script_name: '/x',
                                           only_path: 'false', sort: 'id', q: { enrollment_id: enrollment.id } }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('evil.example')
      expect(response.body).not_to include('https://')
      expect(response.body).to include('href="/admin/rejections?')
      expect(response.body).to include("q%5Benrollment_id%5D=#{enrollment.id}")
    end

    it 'paginates 30 rows per page' do
      32.times { create(:rejection, enrollment: create(:enrollment, :application_complete, user: create(:user, :with_applicant_detail))) }

      get admin_rejections_path
      expect(response.body.scan('<tr id="rejection_').size).to eq(30)
      expect(response.body).to include('rel="next"')

      get admin_rejections_path, params: { page: 2 }
      expect(response.body).to include('Showing <span class="font-medium">31</span>–<span class="font-medium">33</span>')
    end

    it 'exports CSV' do
      get admin_rejections_path(format: :csv)

      expect(response.media_type).to eq('text/csv')
      csv = CSV.parse(response.body)
      expect(csv.first).to eq(['Id', 'Name', 'email', 'Reason', 'Created at', 'Updated at'])
      expect(csv.second[1..3]).to eq(['Zimmerman, Ada', user.email, 'Incomplete transcript'])
    end
  end

  describe 'GET /admin/rejections/:id' do
    it 'renders the attributes and the application status' do
      get admin_rejection_path(rejection)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Zimmerman, Ada')
      expect(response.body).to include(admin_application_path(enrollment))
      expect(response.body).to include('Incomplete transcript')
      expect(response.body).to include('rejected')
    end
  end

  describe 'GET /admin/rejections/new' do
    it 'renders the applicant select without a prefill' do
      get new_admin_rejection_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('name="rejection[enrollment_id]"')
      expect(response.body).to include('<select')
      expect(response.body).to include("Zimmerman, Ada - #{user.email}")
    end

    it 'prefills the applicant from ?enrollment_id= (the "Reject Applicant" entry point)' do
      other = create(:enrollment, :application_complete, user: create(:user, :with_applicant_detail))
      other.applicant_detail.update!(lastname: 'Babbage', firstname: 'Charles')

      get new_admin_rejection_path(enrollment_id: other.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Babbage, Charles')
      expect(response.body).to include(%(type="hidden" value="#{other.id}" name="rejection[enrollment_id]"))
      expect(response.body).to include(admin_application_path(other))
    end

    it 'is linked from the application page' do
      other = create(:enrollment, :application_complete, user: create(:user, :with_applicant_detail))

      get admin_application_path(other)

      expect(response.body).to include(new_admin_rejection_path(enrollment_id: other.id))
    end
  end

  describe 'POST /admin/rejections' do
    let(:other) { create(:enrollment, :application_complete, user: create(:user, :with_applicant_detail)) }

    it 'records the rejection, clears assignments, rejects the application and emails the applicant' do
      create(:course_assignment, enrollment: other, course: Course.first)
      create(:session_assignment, enrollment: other, camp_occurrence: CampOccurrence.active.first)
      ActionMailer::Base.deliveries.clear

      expect do
        post admin_rejections_path, params: { rejection: { enrollment_id: other.id, reason: 'Does not meet requirements' } }
      end.to change(Rejection, :count).by(1)

      created = Rejection.last
      expect(response).to redirect_to(admin_rejection_path(created))
      expect(flash[:notice]).to include('notified')
      other.reload
      expect(other.application_status).to eq('rejected')
      expect(other.course_assignments).to be_empty
      expect(other.session_assignments).to be_empty
      expect(ActionMailer::Base.deliveries.map(&:to).flatten).to include(other.user.email)
    end

    it 're-renders with errors when the reason is blank, keeping the prefilled applicant' do
      post admin_rejections_path, params: { rejection: { enrollment_id: other.id, reason: '' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(CGI.unescapeHTML(response.body)).to include("Reason can't be blank")
      expect(response.body).to include(%(type="hidden" value="#{other.id}" name="rejection[enrollment_id]"))
    end

    it 'refuses to reject an enrolled application instead of failing after the commit' do
      enrolled = create(:enrollment, :enrolled, user: create(:user, :with_applicant_detail))

      expect do
        post admin_rejections_path, params: { rejection: { enrollment_id: enrolled.id, reason: 'Nope' } }
      end.not_to change(Rejection, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('This application is enrolled and cannot be rejected.')
      expect(enrolled.reload.application_status).to eq('enrolled')
    end
  end

  describe 'edit/update' do
    it 'renders the edit form with the applicant read-only' do
      get edit_admin_rejection_path(rejection)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Zimmerman, Ada')
      expect(response.body).not_to include('name="rejection[enrollment_id]"')
      expect(response.body).to include('cannot be changed on an existing rejection')
      expect(response.body).to include('Incomplete transcript')
    end

    it 'updates the reason without re-sending the rejection letter or changing the application' do
      ActionMailer::Base.deliveries.clear

      expect do
        patch admin_rejection_path(rejection), params: { rejection: { reason: 'Updated reason' } }
      end.not_to change { ActionMailer::Base.deliveries.size }

      expect(response).to redirect_to(admin_rejection_path(rejection))
      expect(rejection.reload.reason).to eq('Updated reason')
      expect(enrollment.reload.application_status).to eq('rejected')
    end

    it 'ignores a submitted enrollment_id so a rejection can never be reassigned to a second application' do
      other = create(:enrollment, :application_complete, user: create(:user, :with_applicant_detail))

      patch admin_rejection_path(rejection), params: { rejection: { enrollment_id: other.id, reason: 'Moved' } }

      expect(response).to redirect_to(admin_rejection_path(rejection))
      rejection.reload
      expect(rejection.enrollment).to eq(enrollment)
      expect(rejection.reason).to eq('Moved')
      expect(other.reload.application_status).to eq('application complete')
    end
  end

  describe 'destroy and batch' do
    it 'destroys the rejection' do
      expect { delete admin_rejection_path(rejection) }.to change(Rejection, :count).by(-1)
      expect(response).to redirect_to(admin_rejections_path)
    end

    it 'destroys the selected rejections' do
      expect { post batch_admin_rejections_path, params: { batch_action: 'destroy', ids: [rejection.id] } }
        .to change(Rejection, :count).by(-1)
    end
  end

  describe 'public routes' do
    it 'no longer exposes the unauthenticated /rejections scaffold' do
      sign_out admin

      expect { post '/rejections', params: { rejection: { enrollment_id: enrollment.id, reason: 'x' } } }.not_to change(Rejection, :count)
      expect(response).to have_http_status(:not_found)
      get '/rejections'
      expect(response).to have_http_status(:not_found)
    end
  end

  it 'requires an admin' do
    sign_out admin
    get admin_rejections_path
    expect(response).to redirect_to(new_admin_session_path)
  end
end
