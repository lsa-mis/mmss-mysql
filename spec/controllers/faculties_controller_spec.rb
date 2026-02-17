# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FacultiesController, type: :controller do
  let(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year) }
  let(:camp_occurrence) { create(:camp_occurrence, camp_configuration: camp_config, active: true) }
  let(:faculty_uniqname) { 'testfaculty' }
  let(:faculty_email) { "#{faculty_uniqname}@university.edu" }
  let(:faculty) { create(:faculty, email: faculty_email) }

  before do
    # Ensure faculty has courses in current camp
    create(:course, camp_occurrence: camp_occurrence, faculty_uniqname: faculty_uniqname)
    sign_in faculty
  end

  describe 'GET #index' do
    context 'when faculty is authenticated' do
      let!(:course1) { create(:course, camp_occurrence: camp_occurrence, faculty_uniqname: faculty_uniqname, title: 'Course 1') }
      let!(:course2) { create(:course, camp_occurrence: camp_occurrence, faculty_uniqname: faculty_uniqname, title: 'Course 2') }
      let!(:other_course) { create(:course, camp_occurrence: camp_occurrence, faculty_uniqname: 'otherfaculty', title: 'Other Course') }

      it 'returns http success' do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'assigns only courses for the current faculty' do
        get :index
        expect(assigns(:courses)).to include(course1, course2)
        expect(assigns(:courses)).not_to include(other_course)
      end

      it 'only shows courses from current camp' do
        old_camp_config = create(:camp_configuration, active: false, camp_year: Date.current.year - 1)
        old_camp_occurrence = create(:camp_occurrence, camp_configuration: old_camp_config, active: false)
        old_course = create(:course, camp_occurrence: old_camp_occurrence, faculty_uniqname: faculty_uniqname)

        get :index
        expect(assigns(:courses)).not_to include(old_course)
      end

      it 'uses the faculty layout' do
        get :index
        expect(response).to render_template(layout: 'faculty')
      end
    end

    context 'when faculty is not authenticated' do
      before do
        sign_out faculty
      end

      it 'redirects to sign in page' do
        get :index
        expect(response).to redirect_to(new_faculty_session_path)
      end
    end

    context 'when faculty has no courses' do
      let(:faculty_without_courses_uniqname) { 'nocourses' }
      let(:faculty_without_courses) do
        # Create a course first so faculty can be created (validation requires courses)
        temp_course = create(:course, camp_occurrence: camp_occurrence, faculty_uniqname: faculty_without_courses_uniqname)
        faculty = create(:faculty, email: "#{faculty_without_courses_uniqname}@university.edu")
        # Remove the course association so faculty has no courses
        temp_course.update(faculty_uniqname: 'otherfaculty')
        faculty
      end

      before do
        sign_out faculty
        sign_in faculty_without_courses
      end

      it 'returns empty courses array' do
        get :index
        expect(assigns(:courses)).to be_empty
      end
    end
  end

  describe 'GET #student_list' do
    let(:course) { create(:course, camp_occurrence: camp_occurrence, faculty_uniqname: faculty_uniqname) }
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:enrollment1) { create(:enrollment, user: user1, campyear: camp_config.camp_year) }
    let(:enrollment2) { create(:enrollment, user: user2, campyear: camp_config.camp_year) }
    let!(:course_assignment1) { create(:course_assignment, course: course, enrollment: enrollment1, wait_list: false) }
    let!(:course_assignment2) { create(:course_assignment, course: course, enrollment: enrollment2, wait_list: false) }
    let!(:waitlisted_assignment) { create(:course_assignment, course: course, enrollment: create(:enrollment, user: create(:user), campyear: camp_config.camp_year), wait_list: true) }

    context 'when faculty is authenticated' do
      it 'returns http success' do
        get :student_list, params: { id: course.id }
        expect(response).to have_http_status(:success)
      end

      it 'assigns the correct course' do
        get :student_list, params: { id: course.id }
        expect(assigns(:course)).to eq(course)
      end

      it 'assigns only non-waitlisted students' do
        get :student_list, params: { id: course.id }
        expect(assigns(:students)).to include(enrollment1, enrollment2)
        expect(assigns(:students)).not_to include(waitlisted_assignment.enrollment)
      end

      it 'uses the faculty layout' do
        get :student_list, params: { id: course.id }
        expect(response).to render_template(layout: 'faculty')
      end
    end

    context 'when faculty is not authenticated' do
      before do
        sign_out faculty
      end

      it 'redirects to sign in page' do
        get :student_list, params: { id: course.id }
        expect(response).to redirect_to(new_faculty_session_path)
      end
    end

    context 'when course does not exist' do
      it 'raises an error' do
        expect {
          get :student_list, params: { id: 99999 }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when course has no enrolled students' do
      let(:empty_course) { create(:course, camp_occurrence: camp_occurrence, faculty_uniqname: faculty_uniqname) }

      it 'returns empty students array' do
        get :student_list, params: { id: empty_course.id }
        expect(assigns(:students)).to be_empty
      end
    end
  end

  describe 'GET #student_page' do
    let(:course) { create(:course, camp_occurrence: camp_occurrence, faculty_uniqname: faculty_uniqname) }
    let(:user) { create(:user) }
    let(:enrollment) { create(:enrollment, user: user, campyear: camp_config.camp_year) }
    let!(:course_assignment) { create(:course_assignment, course: course, enrollment: enrollment, wait_list: false) }

    context 'when faculty is authenticated' do
      it 'returns http success' do
        get :student_page, params: { id: enrollment.id }
        expect(response).to have_http_status(:success)
      end

      it 'assigns the correct student enrollment' do
        get :student_page, params: { id: enrollment.id }
        expect(assigns(:student)).to eq(enrollment)
      end

      it 'uses the faculty layout' do
        get :student_page, params: { id: enrollment.id }
        expect(response).to render_template(layout: 'faculty')
      end
    end

    context 'when faculty is not authenticated' do
      before do
        sign_out faculty
      end

      it 'redirects to sign in page' do
        get :student_page, params: { id: enrollment.id }
        expect(response).to redirect_to(new_faculty_session_path)
      end
    end

    context 'when enrollment does not exist' do
      it 'assigns nil to student' do
        get :student_page, params: { id: 99999 }
        expect(assigns(:student)).to be_nil
      end

      it 'still returns success (does not raise error)' do
        expect {
          get :student_page, params: { id: 99999 }
        }.not_to raise_error
      end
    end
  end
end
