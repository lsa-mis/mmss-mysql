# frozen_string_literal: true

require 'rails_helper'

# Turbo Drive submits non-GET links/forms with fetch. A 302 after a DELETE or
# PATCH is re-issued with the same verb against the redirect target, so every
# non-GET action must answer 303 See Other for Turbo to follow it with a GET.
RSpec.describe 'Turbo-compatible redirects after non-GET requests', type: :request do
  let(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year) }
  let(:camp_occurrence) { create(:camp_occurrence, camp_configuration: camp_config, active: true) }

  describe 'DELETE /faculties/sign_out (Faculties::SessionsController#destroy)' do
    let(:faculty) { create(:faculty, email: 'prof@university.edu') }

    before do
      create(:course, camp_occurrence: camp_occurrence, faculty_uniqname: 'prof')
      sign_in faculty
    end

    it 'redirects to the faculty login page with 303 See Other' do
      delete destroy_faculty_session_path

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(faculty_login_path)
    end

    it 'signs the faculty out' do
      delete destroy_faculty_session_path
      follow_redirect!

      get faculty_path
      expect(response).to redirect_to(new_faculty_session_path)
    end
  end

  describe 'POST /faculties/sign_in (Faculties::SessionsController#create)' do
    let(:faculty) { create(:faculty, email: 'prof@university.edu') }

    it 'redirects with 303 when the faculty teaches a current course' do
      create(:course, camp_occurrence: camp_occurrence, faculty_uniqname: 'prof')

      post faculty_session_path, params: { faculty: { email: faculty.email, password: faculty.password } }

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(faculty_path)
    end
  end

  describe 'DELETE /users/sign_out (Devise responder)' do
    it 'redirects with 303 See Other' do
      sign_in create(:user)

      delete destroy_user_session_path

      expect(response).to have_http_status(:see_other)
    end
  end

  describe 'session offer links from the progress sidebox' do
    let(:user) { create(:user) }
    let(:enrollment) do
      create(:enrollment, user: user, campyear: camp_config.camp_year,
                          application_status: 'offer accepted', offer_status: 'offered')
    end
    let(:course) { create(:course, camp_occurrence: camp_occurrence) }
    let!(:course_assignment) { create(:course_assignment, enrollment: enrollment, course: course) }
    let!(:session_assignment) { create(:session_assignment, enrollment: enrollment, camp_occurrence: camp_occurrence) }

    before { sign_in user }

    describe 'POST /accept_session_offer/:id' do
      it 'accepts the offer and redirects to the account summary with 303' do
        post accept_session_offer_path(session_assignment)

        expect(response).to have_http_status(:see_other)
        expect(response).to redirect_to(all_payments_path)
        expect(session_assignment.reload.offer_status).to eq('accepted')
        expect(enrollment.reload.offer_status).to eq('accepted')
      end
    end

    describe 'POST /decline_session_offer/:id' do
      it 'declines the offer and redirects home with 303' do
        post decline_session_offer_path(session_assignment)

        expect(response).to have_http_status(:see_other)
        expect(response).to redirect_to(root_path)
        expect(session_assignment.reload.offer_status).to eq('declined')
        expect(enrollment.reload.offer_status).to eq('declined')
        expect(CourseAssignment.where(enrollment: enrollment)).to be_empty
      end
    end
  end

  describe 'admin create/update/destroy' do
    before { sign_in create(:admin) }

    it 'answers 303 after create, update and destroy' do
      post admin_gender_types_path, params: { gender: { name: 'Probe', description: 'probe' } }
      expect(response).to have_http_status(:see_other)
      gender = Gender.find_by!(name: 'Probe')

      patch admin_gender_type_path(gender), params: { gender: { description: 'updated' } }
      expect(response).to have_http_status(:see_other)

      delete admin_gender_type_path(gender)
      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(admin_gender_types_url)
    end
  end
end
