# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin course assignments', type: :request do
  let(:admin) { create(:admin) }
  let(:user) { create(:user, :with_applicant_detail) }
  let(:enrollment) { create(:enrollment, user: user) }
  let(:session) { CampOccurrence.active.first }
  let(:course) { create(:course, camp_occurrence: session, title: 'Number Theory') }
  let!(:assignment) { create(:course_assignment, enrollment: enrollment, course: course) }

  before do
    user.applicant_detail.update!(lastname: 'Zimmerman', firstname: 'Ada')
    sign_in admin
  end

  describe 'GET /admin/course_assignments' do
    it 'lists assignments with applicant links, filters, batch actions and CSV' do
      get admin_course_assignments_path

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('Zimmerman, Ada')
      expect(body).to include(admin_application_path(enrollment))
      expect(body).to include('Number Theory')
      expect(body).to include('With selected:')
      expect(body).to include('Download CSV')
      expect(body).to include(edit_admin_course_assignment_path(assignment))
      expect(body).to include('name="q[enrollment_id]"')
      expect(body).to include('name="q[course_id]"')
    end

    it 'filters by enrollment and course' do
      other_course = create(:course, camp_occurrence: session, title: 'Topology')
      other = create(:course_assignment, enrollment: create(:enrollment, user: create(:user, :with_applicant_detail)), course: other_course)

      get admin_course_assignments_path, params: { q: { enrollment_id: enrollment.id } }
      expect(response.body).to include(edit_admin_course_assignment_path(assignment))
      expect(response.body).not_to include(edit_admin_course_assignment_path(other))

      get admin_course_assignments_path, params: { q: { course_id: other_course.id } }
      expect(response.body).to include(edit_admin_course_assignment_path(other))
      expect(response.body).not_to include(edit_admin_course_assignment_path(assignment))
    end

    it 'sorts by applicant and course through the joins and ignores unknown keys' do
      get admin_course_assignments_path, params: { sort: 'enrollment', direction: 'desc' }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('direction=asc')

      get admin_course_assignments_path, params: { sort: 'course' }
      expect(response).to have_http_status(:ok)

      get admin_course_assignments_path, params: { sort: 'nope' }
      expect(response).to have_http_status(:ok)
    end

    it 'never turns URL options smuggled into the query string into off-site links' do
      get admin_course_assignments_path, params: { host: 'evil.example', protocol: 'https', port: 8443, script_name: '/x',
                                                   only_path: 'false', sort: 'course', q: { course_id: course.id } }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('evil.example')
      expect(response.body).not_to include('https://')
      expect(response.body).to include('href="/admin/course_assignments?')
      expect(response.body).to include('direction=desc')
      expect(response.body).to include("q%5Bcourse_id%5D=#{course.id}")
    end

    it 'paginates 30 rows per page' do
      32.times { create(:course_assignment, enrollment: create(:enrollment, user: create(:user, :with_applicant_detail)), course: course) }

      get admin_course_assignments_path

      expect(response).to have_http_status(:ok)
      expect(response.body.scan('<tr id="course_assignment_').size).to eq(30)
      expect(response.body).to include('rel="next"')

      get admin_course_assignments_path, params: { page: 2 }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Showing <span class="font-medium">31</span>–<span class="font-medium">33</span>')
      expect(response.body).to include('rel="prev"')
    end

    it 'exports the ActiveAdmin CSV columns' do
      get admin_course_assignments_path(format: :csv)

      expect(response.media_type).to eq('text/csv')
      csv = CSV.parse(response.body)
      expect(csv.first).to eq(%w[Name email Course Session])
      expect(csv.second).to eq(['Zimmerman, Ada', user.email, 'Number Theory', session.display_name])
    end
  end

  describe 'GET /admin/course_assignments/:id' do
    it 'renders the attributes and comments' do
      get admin_course_assignment_path(assignment)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Zimmerman, Ada')
      expect(response.body).to include(admin_application_path(enrollment))
      expect(response.body).to include('Number Theory')
      expect(response.body).to include('Add a comment')
      expect(response.body).to include('resource_type" value="CourseAssignment"')
    end

    it 'accepts admin comments' do
      post admin_comments_path, params: { resource_type: 'CourseAssignment', resource_id: assignment.id, admin_comment: { body: 'Moved from wait list' } },
                                headers: { 'HTTP_REFERER' => admin_course_assignment_path(assignment) }

      expect(response).to redirect_to(admin_course_assignment_path(assignment))
      expect(assignment.admin_comments.pluck(:body)).to eq(['Moved from wait list'])
    end
  end

  describe 'GET /admin/course_assignments/new and POST' do
    it 'renders the form with current-year applicants and active-session courses' do
      get new_admin_course_assignment_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Zimmerman, Ada - #{user.email}")
      expect(response.body).to include('Number Theory')
      expect(response.body).to include('name="course_assignment[wait_list]"')
    end

    it 'creates an assignment' do
      other = create(:enrollment, user: create(:user, :with_applicant_detail))

      expect do
        post admin_course_assignments_path, params: { course_assignment: { enrollment_id: other.id, course_id: course.id, wait_list: '1' } }
      end.to change(CourseAssignment, :count).by(1)

      created = CourseAssignment.last
      expect(created.wait_list).to be(true)
      expect(response).to redirect_to(admin_course_assignment_path(created))
    end

    it 're-renders with errors when invalid' do
      post admin_course_assignments_path, params: { course_assignment: { enrollment_id: '', course_id: course.id } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('Enrollment must exist')
    end
  end

  describe 'GET /admin/course_assignments/:id/edit and PATCH' do
    it 'keeps a course from an inactive session selectable' do
      inactive = create(:camp_occurrence, camp_configuration: session.camp_configuration, active: false, description: 'Retired')
      old_course = create(:course, camp_occurrence: inactive, title: 'Ancient Algebra')
      assignment.update!(course: old_course)

      get edit_admin_course_assignment_path(assignment)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Ancient Algebra')
    end

    it 'updates the assignment' do
      patch admin_course_assignment_path(assignment), params: { course_assignment: { wait_list: '1' } }

      expect(response).to redirect_to(admin_course_assignment_path(assignment))
      expect(assignment.reload.wait_list).to be(true)
    end
  end

  describe 'DELETE /admin/course_assignments/:id' do
    it 'destroys the assignment' do
      expect { delete admin_course_assignment_path(assignment) }.to change(CourseAssignment, :count).by(-1)
      expect(response).to redirect_to(admin_course_assignments_path)
    end
  end

  describe 'POST /admin/course_assignments/batch' do
    it 'destroys the selected assignments' do
      expect { post batch_admin_course_assignments_path, params: { batch_action: 'destroy', ids: [assignment.id] } }
        .to change(CourseAssignment, :count).by(-1)
      expect(response).to redirect_to(admin_course_assignments_path)
    end
  end

  it 'requires an admin' do
    sign_out admin
    get admin_course_assignments_path
    expect(response).to redirect_to(new_admin_session_path)
  end
end
