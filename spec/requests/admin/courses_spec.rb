# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin courses', type: :request do
  let(:admin) { create(:admin) }
  let(:camp) { create(:camp_configuration, :active, camp_year: 2031) }
  let(:session) { create(:camp_occurrence, camp_configuration: camp, description: 'Session Alpha', active: true) }
  let!(:course) do
    create(:course, camp_occurrence: session, title: 'Number Theory', available_spaces: 10, status: 'open',
                    faculty_uniqname: 'gauss', faculty_name: 'Carl Gauss')
  end

  before { sign_in admin }

  describe 'GET /admin/courses' do
    it 'lists current camp courses with scopes, seat counts, filters and batch actions' do
      enrollment = create(:enrollment, user: create(:user, :with_applicant_detail))
      create(:course_assignment, course: course, enrollment: enrollment, wait_list: false)
      create(:course_assignment, course: course, enrollment: create(:enrollment, user: create(:user, :with_applicant_detail)), wait_list: true)

      get admin_courses_path

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('Number Theory')
      expect(body).to include('Current Camp Courses')
      expect(body).to include('Open Spaces')
      expect(body).to include('Wait List')
      expect(body).to include('Toggle open/closed')
      expect(body).to include('Download CSV')
      expect(body).to include(admin_session_configuration_path(session))
      # available 10 - 1 confirmed = 9 open, 1 wait listed
      expect(body).to match(%r{<td[^>]*>10</td>\s*<td[^>]*>9</td>\s*<td[^>]*>\s*1\s*</td>})
    end

    it 'scopes to the current camp by default and shows everything under All' do
      old_camp = create(:camp_configuration, camp_year: 2020)
      old_session = create(:camp_occurrence, camp_configuration: old_camp, description: 'Old Session', active: false)
      old_course = create(:course, camp_occurrence: old_session, title: 'Ancient Algebra')

      get admin_courses_path
      expect(response.body).to include(edit_admin_course_path(course))
      expect(response.body).not_to include(edit_admin_course_path(old_course))

      get admin_courses_path, params: { scope: 'all' }
      expect(response.body).to include(edit_admin_course_path(old_course))
    end

    it 'filters by session, title, available spaces and status' do
      other = create(:course, camp_occurrence: session, title: 'Topology', available_spaces: 5, status: 'closed')
      nt_row = edit_admin_course_path(course)
      topo_row = edit_admin_course_path(other)

      get admin_courses_path, params: { q: { title: 'topol' } }
      expect(response.body).to include(topo_row)
      expect(response.body).not_to include(nt_row)

      get admin_courses_path, params: { q: { available_spaces: '10' } }
      expect(response.body).to include(nt_row)
      expect(response.body).not_to include(topo_row)

      get admin_courses_path, params: { q: { status: 'closed' } }
      expect(response.body).to include(topo_row)
      expect(response.body).not_to include(nt_row)

      get admin_courses_path, params: { q: { camp_occurrence_id: session.id } }
      expect(response.body).to include(nt_row)
      expect(response.body).to include(topo_row)
    end

    it 'never turns URL options smuggled into the query string into off-site links' do
      get admin_courses_path, params: { host: 'evil.example', protocol: 'https', port: 8443, script_name: '/x',
                                        only_path: 'false', sort: 'title', scope: 'all', q: { title: 'Number' } }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('evil.example')
      expect(response.body).not_to include('https://')
      expect(response.body).to include('href="/admin/courses?')
      expect(response.body).to include('direction=desc')
      expect(response.body).to include('q%5Btitle%5D=Number')
      expect(response.body).to include('scope=current_camp')
    end

    it 'sorts by session through the join and ignores unknown keys' do
      get admin_courses_path, params: { sort: 'session', direction: 'desc' }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('direction=asc')

      get admin_courses_path, params: { sort: 'nope' }
      expect(response).to have_http_status(:ok)
    end

    it 'exports CSV with seat counts' do
      get admin_courses_path(format: :csv)

      expect(response.media_type).to eq('text/csv')
      csv = CSV.parse(response.body)
      expect(csv.first).to eq(['Id', 'Session', 'Title', 'Available spaces', 'Open spaces', 'Wait list', 'Status',
                               'Faculty uniqname', 'Faculty name', 'Created at', 'Updated at'])
      expect(csv.second[1..8]).to eq(['Session Alpha', 'Number Theory', '10', '10', '0', 'open', 'gauss', 'Carl Gauss'])
    end
  end

  describe 'GET /admin/courses/:id' do
    it 'renders attributes, the list of students and comments' do
      user = create(:user, :with_applicant_detail)
      user.applicant_detail.update!(lastname: 'Noether', firstname: 'Emmy')
      enrollment = create(:enrollment, user: user)
      create(:course_assignment, course: course, enrollment: enrollment, wait_list: true)

      get admin_course_path(course)

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('Number Theory')
      expect(body).to include('List of students (1)')
      expect(body).to include('Noether, Emmy')
      expect(body).to include(admin_application_path(enrollment))
      expect(body).to include(user.email)
      expect(body).to include('Add a comment')
      expect(body).to include('resource_type" value="Course"')
    end

    it 'accepts admin comments' do
      post admin_comments_path, params: { resource_type: 'Course', resource_id: course.id, admin_comment: { body: 'Needs a TA' } },
                                headers: { 'HTTP_REFERER' => admin_course_path(course) }

      expect(response).to redirect_to(admin_course_path(course))
      expect(course.admin_comments.pluck(:body)).to eq(['Needs a TA'])
    end
  end

  describe 'GET /admin/courses/:id/edit' do
    it 'offers active sessions plus the current one' do
      inactive = create(:camp_occurrence, camp_configuration: camp, description: 'Retired Session', active: false)
      course.update!(camp_occurrence: inactive)

      get edit_admin_course_path(course)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Retired Session')
      expect(response.body).to include('Session Alpha')
      expect(response.body).to include('name="course[status]"')
    end

    it 'keeps a non-standard persisted status selectable' do
      course.update_columns(status: 'waitlist only')

      get edit_admin_course_path(course)

      expect(response.body).to include('<option selected="selected" value="waitlist only">waitlist only</option>')
    end
  end

  describe 'POST /admin/courses' do
    it 'creates a course' do
      params = { camp_occurrence_id: session.id, title: 'Cryptography', available_spaces: 12, status: 'open',
                 faculty_uniqname: 'turing', faculty_name: 'Alan Turing' }

      expect { post admin_courses_path, params: { course: params } }.to change(Course, :count).by(1)
      expect(response).to redirect_to(admin_course_path(Course.find_by!(title: 'Cryptography')))
    end

    it 're-renders with errors when invalid' do
      post admin_courses_path, params: { course: { camp_occurrence_id: session.id, title: '', faculty_uniqname: 'bad@umich.edu' } }

      expect(response).to have_http_status(:unprocessable_content)
      body = CGI.unescapeHTML(response.body)
      expect(body).to include("Title can't be blank")
      expect(body).to include('do not include domain')
    end
  end

  describe 'PATCH /admin/courses/:id' do
    it 'updates the course' do
      patch admin_course_path(course), params: { course: { status: 'closed', available_spaces: 8 } }

      expect(response).to redirect_to(admin_course_path(course))
      course.reload
      expect(course.status).to eq('closed')
      expect(course.available_spaces).to eq(8)
    end
  end

  describe 'DELETE /admin/courses/:id' do
    it 'destroys the course' do
      expect { delete admin_course_path(course) }.to change(Course, :count).by(-1)
      expect(response).to redirect_to(admin_courses_path)
    end
  end

  describe 'POST /admin/courses/batch' do
    it 'toggles open/closed' do
      closed = create(:course, camp_occurrence: session, status: 'closed')

      post batch_admin_courses_path, params: { batch_action: 'toggle_status', ids: [course.id, closed.id] }

      expect(response).to redirect_to(admin_courses_path)
      expect(flash[:notice]).to include('Toggled status for 2 courses')
      expect(course.reload.status).to eq('closed')
      expect(closed.reload.status).to eq('open')
    end

    it 'destroys the selected courses' do
      expect { post batch_admin_courses_path, params: { batch_action: 'destroy', ids: [course.id] } }
        .to change(Course, :count).by(-1)
    end
  end

  it 'requires an admin' do
    sign_out admin
    get admin_courses_path
    expect(response).to redirect_to(new_admin_session_path)
  end
end
