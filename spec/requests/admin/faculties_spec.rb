# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin faculties', type: :request do
  let(:admin) { create(:admin) }
  let(:camp_configuration) { create(:camp_configuration, :current_year) }
  let(:session) { create(:camp_occurrence, camp_configuration: camp_configuration, active: true) }
  let!(:course) { create(:course, camp_occurrence: session, faculty_uniqname: 'jsmith', title: 'Number Theory') }
  let!(:faculty) { create(:faculty, :with_sign_ins, email: 'jsmith@umich.edu') }

  before { sign_in admin }

  describe 'GET /admin/faculties' do
    it 'lists faculty accounts with view/delete actions only, batch actions and CSV link, no filters' do
      get admin_faculties_path

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('jsmith@umich.edu')
      expect(body).to include(admin_faculty_path(faculty))
      expect(body).to include('With selected:')
      expect(body).to include('Download CSV')
      expect(body).not_to include('Filters')
      expect(body).not_to include('New Faculty')
      expect(body).not_to include("/admin/faculties/#{faculty.id}/edit")
    end

    it 'sorts by an allowed column and ignores unknown ones' do
      create(:course, camp_occurrence: session, faculty_uniqname: 'adoe')
      create(:faculty, email: 'adoe@umich.edu')

      get admin_faculties_path, params: { sort: 'email', direction: 'desc' }
      expect(response).to have_http_status(:ok)
      expect(response.body.index('jsmith@umich.edu')).to be < response.body.index('adoe@umich.edu')

      get admin_faculties_path, params: { sort: 'encrypted_password' }
      expect(response).to have_http_status(:ok)
    end

    it 'never turns URL options smuggled into the query string into off-site links' do
      get admin_faculties_path, params: { host: 'evil.example', protocol: 'https', port: 8443, script_name: '/x', only_path: 'false',
                              sort: 'email', direction: 'asc' }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('evil.example')
      expect(response.body).not_to include('https://')
      expect(response.body).to include('href="/admin/faculties?')
      expect(response.body).to include('direction=desc')
    end

    it 'exports CSV without credential columns' do
      get admin_faculties_path(format: :csv)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/csv')
      expect(response.headers['Content-Disposition']).to include('MMSS-faculties-')
      csv = CSV.parse(response.body)
      expect(csv.first).to eq(['Id', 'Email', 'Current sign in at', 'Last sign in at', 'Sign in count', 'Created at', 'Updated at'])
      expect(csv.second[1]).to eq('jsmith@umich.edu')
    end
  end

  describe 'GET /admin/faculties/:id' do
    it 'renders the account and the courses for the current camp' do
      create(:course, camp_occurrence: create(:camp_occurrence, :inactive, camp_configuration: camp_configuration), faculty_uniqname: 'jsmith', title: 'Old Course')

      get admin_faculty_path(faculty)

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include("Faculty ##{faculty.id}")
      expect(body).to include('jsmith')
      expect(body).to include('Courses for current camp')
      expect(body).to include('Number Theory')
      expect(body).not_to include('Old Course')
      expect(body).to include(course.available_spaces.to_s)
      expect(body).to include('Sign-in activity')
      expect(body).to include(faculty.current_sign_in_ip)
    end

    it 'shows an empty state when the faculty has no current courses' do
      course.update!(faculty_uniqname: 'someone_else')

      get admin_faculty_path(faculty)

      expect(response.body).to include('No courses in the current camp')
    end
  end

  it 'has no new or edit routes' do
    expect { get '/admin/faculties/new' }.not_to raise_error
    expect(response).to redirect_to(admin_root_path) # "new" is treated as an id and not found

    expect(Rails.application.routes.url_helpers).not_to respond_to(:edit_admin_faculty_path)
  end

  describe 'DELETE /admin/faculties/:id' do
    it 'destroys the faculty' do
      expect { delete admin_faculty_path(faculty) }.to change(Faculty, :count).by(-1)
      expect(response).to redirect_to(admin_faculties_path)
    end
  end

  describe 'POST /admin/faculties/batch' do
    it 'destroys the selected faculties' do
      create(:course, camp_occurrence: session, faculty_uniqname: 'adoe')
      other = create(:faculty, email: 'adoe@umich.edu')

      expect do
        post batch_admin_faculties_path, params: { batch_action: 'destroy', ids: [faculty.id, other.id] }
      end.to change(Faculty, :count).by(-2)

      expect(response).to redirect_to(admin_faculties_path)
      expect(flash[:notice]).to include('Deleted 2')
    end
  end

  it 'requires an admin' do
    sign_out admin

    get admin_faculties_path

    expect(response).to redirect_to(new_admin_session_path)
  end
end
