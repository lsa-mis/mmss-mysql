# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Faculties', type: :request do
  let(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year) }
  let(:camp_occurrence) { create(:camp_occurrence, camp_configuration: camp_config, active: true) }
  let(:faculty_uniqname) { 'testfaculty' }
  let(:faculty_email) { "#{faculty_uniqname}@university.edu" }
  let(:faculty) { create(:faculty, email: faculty_email) }

  before do
    # Ensure faculty has courses in current camp
    create(:course, camp_occurrence: camp_occurrence, faculty_uniqname: faculty_uniqname)
  end

  describe 'GET /faculty' do
    context 'when faculty is authenticated' do
      let!(:course1) { create(:course, camp_occurrence: camp_occurrence, faculty_uniqname: faculty_uniqname, title: 'Course 1', available_spaces: 10, status: 'open') }
      let!(:course2) { create(:course, camp_occurrence: camp_occurrence, faculty_uniqname: faculty_uniqname, title: 'Course 2', available_spaces: 5, status: 'closed') }

      before do
        sign_in faculty
      end

      it 'returns http success' do
        get faculty_path
        expect(response).to have_http_status(:success)
      end

      it 'renders the index template' do
        get faculty_path
        expect(response).to render_template(:index)
      end

      it 'displays courses for the faculty' do
        get faculty_path
        expect(response.body).to include('Course 1')
        expect(response.body).to include('Course 2')
        expect(response.body).to include('10') # available_spaces
        expect(response.body).to include('5') # available_spaces
        expect(response.body).to include('open')
        expect(response.body).to include('closed')
      end

      it 'includes links to student lists' do
        get faculty_path
        expect(response.body).to include('Student List')
        expect(response.body).to include(student_list_path(course1))
        expect(response.body).to include(student_list_path(course2))
      end

      it 'does not display courses for other faculty' do
        create(:course, camp_occurrence: camp_occurrence, faculty_uniqname: 'otherfaculty', title: 'Other Course')
        get faculty_path
        expect(response.body).not_to include('Other Course')
      end
    end

    context 'when faculty is not authenticated' do
      it 'redirects to sign in page' do
        get faculty_path
        expect(response).to redirect_to(new_faculty_session_path)
      end
    end
  end

  describe 'GET /faculty/student_list/:id' do
    let(:course) { create(:course, camp_occurrence: camp_occurrence, faculty_uniqname: faculty_uniqname, title: 'Test Course') }
    let(:user1) { create(:user, email: 'student1@example.com') }
    let(:user2) { create(:user, email: 'student2@example.com') }
    let(:enrollment1) { create(:enrollment, user: user1, campyear: camp_config.camp_year) }
    let(:enrollment2) { create(:enrollment, user: user2, campyear: camp_config.camp_year) }
    
    before do
      # Ensure users have applicant_details for display
      create(:applicant_detail, user: user1) unless user1.applicant_detail
      create(:applicant_detail, user: user2) unless user2.applicant_detail
    end
    let!(:course_assignment1) { create(:course_assignment, course: course, enrollment: enrollment1, wait_list: false) }
    let!(:course_assignment2) { create(:course_assignment, course: course, enrollment: enrollment2, wait_list: false) }
    let!(:waitlisted_assignment) do
      waitlisted_user = create(:user, email: 'waitlisted@example.com')
      create(:applicant_detail, user: waitlisted_user) unless waitlisted_user.applicant_detail
      waitlisted_enrollment = create(:enrollment, user: waitlisted_user, campyear: camp_config.camp_year)
      create(:course_assignment, course: course, enrollment: waitlisted_enrollment, wait_list: true)
    end

    context 'when faculty is authenticated' do
      before do
        sign_in faculty
      end

      it 'returns http success' do
        get student_list_path(course)
        expect(response).to have_http_status(:success)
      end

      it 'renders the student_list template' do
        get student_list_path(course)
        expect(response).to render_template(:student_list)
      end

      it 'displays course information' do
        get student_list_path(course)
        expect(response.body).to include('Test Course')
        expect(response.body).to include(course.display_name)
        expect(response.body).to include(course.available_spaces.to_s)
        expect(response.body).to include(course.status)
      end

      it 'displays enrolled students' do
        get student_list_path(course)
        expect(response.body).to include(user1.email)
        expect(response.body).to include(user2.email)
      end

      it 'does not display waitlisted students' do
        get student_list_path(course)
        expect(response.body).not_to include('waitlisted@example.com')
      end

      it 'includes links to individual student pages' do
        get student_list_path(course)
        expect(response.body).to include(student_page_path(enrollment1))
        expect(response.body).to include(student_page_path(enrollment2))
      end

      it 'includes a back link to courses list' do
        get student_list_path(course)
        expect(response.body).to include('Back to courses list')
        expect(response.body).to include(faculty_path)
      end
    end

    context 'when faculty is not authenticated' do
      it 'redirects to sign in page' do
        get student_list_path(course)
        expect(response).to redirect_to(new_faculty_session_path)
      end
    end

    context 'when course does not exist' do
      before do
        sign_in faculty
      end

      it 'raises an error' do
        expect {
          get student_list_path(99999)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'GET /faculty/student_page/:id' do
    let(:course) { create(:course, camp_occurrence: camp_occurrence, faculty_uniqname: faculty_uniqname) }
    let(:user) { create(:user, email: 'student@example.com') }
    let(:enrollment) { create(:enrollment, user: user, campyear: camp_config.camp_year, personal_statement: Faker::Lorem.paragraph_by_chars(number: 150)) }
    let!(:course_assignment) { create(:course_assignment, course: course, enrollment: enrollment, wait_list: false) }
    
    before do
      # Ensure user has applicant_detail for display
      create(:applicant_detail, user: user) unless user.applicant_detail
    end

    context 'when faculty is authenticated' do
      before do
        sign_in faculty
      end

      it 'returns http success' do
        get student_page_path(enrollment)
        expect(response).to have_http_status(:success)
      end

      it 'renders the student_page template' do
        get student_page_path(enrollment)
        expect(response).to render_template(:student_page)
      end

      it 'displays student information' do
        get student_page_path(enrollment)
        expect(response.body).to include(user.email)
        expect(response.body).to include(enrollment.personal_statement)
      end

      it 'displays student name' do
        get student_page_path(enrollment)
        expect(response.body).to include(enrollment.applicant_detail.full_name) if enrollment.applicant_detail
      end

      it 'includes a back link' do
        get student_page_path(enrollment)
        expect(response.body).to include('Back to student list')
      end
    end

    context 'when faculty is not authenticated' do
      it 'redirects to sign in page' do
        get student_page_path(enrollment)
        expect(response).to redirect_to(new_faculty_session_path)
      end
    end

    context 'when enrollment does not exist' do
      before do
        sign_in faculty
      end

      it 'does not raise RecordNotFound for missing enrollment' do
        # Controller uses find_by, so RecordNotFound is not raised. View currently errors when @student is nil.
        expect { get student_page_path(99999) }.to raise_error(ActionView::Template::Error, /applicant_detail.*nil/)
      end
    end
  end

  describe 'authentication requirements' do
    it 'requires authentication for index' do
      get faculty_path
      expect(response).to redirect_to(new_faculty_session_path)
    end

    it 'requires authentication for student_list' do
      course = create(:course, camp_occurrence: camp_occurrence, faculty_uniqname: faculty_uniqname)
      get student_list_path(course)
      expect(response).to redirect_to(new_faculty_session_path)
    end

    it 'requires authentication for student_page' do
      student_user = create(:user)
      create(:applicant_detail, user: student_user) unless student_user.applicant_detail
      enrollment = create(:enrollment, user: student_user, campyear: camp_config.camp_year)
      get student_page_path(enrollment)
      expect(response).to redirect_to(new_faculty_session_path)
    end
  end

  describe 'layout usage' do
    before do
      sign_in faculty
    end

    it 'uses faculty layout for index' do
      get faculty_path
      expect(response).to render_template(layout: 'faculty')
    end

    it 'uses faculty layout for student_list' do
      course = create(:course, camp_occurrence: camp_occurrence, faculty_uniqname: faculty_uniqname)
      get student_list_path(course)
      expect(response).to render_template(layout: 'faculty')
    end

    it 'uses faculty layout for student_page' do
      student_user = create(:user)
      create(:applicant_detail, user: student_user) unless student_user.applicant_detail
      enrollment = create(:enrollment, user: student_user, campyear: camp_config.camp_year)
      get student_page_path(enrollment)
      expect(response).to render_template(layout: 'faculty')
    end
  end
end
