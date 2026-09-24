# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin travels', type: :request do
  let(:admin) { create(:admin) }
  let(:user) { create(:user, :with_applicant_detail) }
  let(:enrollment) { create(:enrollment, user: user) }
  let(:session) { CampOccurrence.active.first }
  let(:session_label) { session.description_with_month_and_day }
  let!(:travel) do
    create(:travel, enrollment: enrollment, arrival_session: session_label, depart_session: session_label,
                    arrival_transport: 'Airplane', arrival_carrier: 'Delta', arrival_route_num: 'DL123',
                    arrival_date: Date.new(2031, 7, 6), arrival_time: Time.zone.parse('2000-01-01 14:30'),
                    depart_transport: 'Train', depart_carrier: 'Amtrak', depart_route_num: '350',
                    depart_date: Date.new(2031, 7, 20), depart_time: Time.zone.parse('2000-01-01 09:05'), note: 'Needs a shuttle')
  end

  before do
    user.applicant_detail.update!(lastname: 'Zimmerman', firstname: 'Ada')
    sign_in admin
  end

  describe 'GET /admin/travels' do
    it 'lists travels with the applicant link, formatted dates/times, filters and batch actions' do
      get admin_travels_path

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('Zimmerman, Ada')
      expect(body).to include(admin_application_path(enrollment))
      expect(body).to include(session_label)
      expect(body).to include('Sunday, 06 Jul 2031')
      expect(body).to include('02:30 PM')
      expect(body).to include('Sunday, 20 Jul 2031')
      expect(body).to include('09:05 AM')
      expect(body).to include('Delta')
      expect(body).to include('Needs a shuttle')
      expect(body).to include('With selected:')
      expect(body).to include('Download CSV')
      expect(body).to include(edit_admin_travel_path(travel))
      expect(body).to include('Last Name (Starts with)')
      expect(body).to include('Session of Arrival')
      expect(body).to include('Departure Transport')
    end

    it 'filters by applicant names through the two-level join, sessions, dates and transports' do
      other_user = create(:user, :with_applicant_detail)
      other_user.applicant_detail.update!(lastname: 'Anderson', firstname: 'Bo')
      other = create(:travel, enrollment: create(:enrollment, user: other_user), arrival_session: 'Session Omega: July 01 to July 08',
                              depart_session: 'Session Omega: July 01 to July 08', arrival_transport: 'Bus', depart_transport: 'Bus',
                              arrival_date: Date.new(2031, 7, 1), depart_date: Date.new(2031, 7, 8))

      get admin_travels_path, params: { q: { lastname: 'Zim' } }
      expect(response.body).to include(edit_admin_travel_path(travel))
      expect(response.body).not_to include(edit_admin_travel_path(other))

      get admin_travels_path, params: { q: { firstname: 'Bo' } }
      expect(response.body).to include(edit_admin_travel_path(other))
      expect(response.body).not_to include(edit_admin_travel_path(travel))

      get admin_travels_path, params: { q: { arrival_session: 'Session Omega: July 01 to July 08' } }
      expect(response.body).to include(edit_admin_travel_path(other))
      expect(response.body).not_to include(edit_admin_travel_path(travel))

      get admin_travels_path, params: { q: { depart_session: session_label } }
      expect(response.body).to include(edit_admin_travel_path(travel))
      expect(response.body).not_to include(edit_admin_travel_path(other))

      get admin_travels_path, params: { q: { arrival_date_from: '2031-07-05', arrival_date_to: '2031-07-07' } }
      expect(response.body).to include(edit_admin_travel_path(travel))
      expect(response.body).not_to include(edit_admin_travel_path(other))

      get admin_travels_path, params: { q: { depart_date_to: '2031-07-10' } }
      expect(response.body).to include(edit_admin_travel_path(other))
      expect(response.body).not_to include(edit_admin_travel_path(travel))

      get admin_travels_path, params: { q: { arrival_transport: 'Bus' } }
      expect(response.body).to include(edit_admin_travel_path(other))
      expect(response.body).not_to include(edit_admin_travel_path(travel))

      get admin_travels_path, params: { q: { depart_transport: 'Train' } }
      expect(response.body).to include(edit_admin_travel_path(travel))
      expect(response.body).not_to include(edit_admin_travel_path(other))
    end

    it 'sorts by applicant through the join and by travel columns' do
      %w[applicant arrival_date depart_time arrival_session nope].each do |key|
        get admin_travels_path, params: { sort: key, direction: 'desc' }
        expect(response).to have_http_status(:ok)
      end
    end

    it 'never turns URL options smuggled into the query string into off-site links' do
      get admin_travels_path, params: { host: 'evil.example', protocol: 'https', port: 8443, script_name: '/x',
                                        only_path: 'false', sort: 'arrival_date', q: { lastname: 'Zim' } }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('evil.example')
      expect(response.body).not_to include('https://')
      expect(response.body).to include('href="/admin/travels?')
      expect(response.body).to include('q%5Blastname%5D=Zim')
    end

    it 'paginates 30 rows per page' do
      32.times { create(:travel, enrollment: create(:enrollment, user: create(:user, :with_applicant_detail))) }

      get admin_travels_path
      expect(response.body.scan('<tr id="travel_').size).to eq(30)
      expect(response.body).to include('rel="next"')

      get admin_travels_path, params: { page: 2 }
      expect(response.body).to include('Showing <span class="font-medium">31</span>–<span class="font-medium">33</span>')
    end

    it 'exports the ActiveAdmin CSV columns with formatted dates and times' do
      get admin_travels_path(format: :csv)

      expect(response.media_type).to eq('text/csv')
      csv = CSV.parse(response.body)
      expect(csv.first).to eq(['Name', 'email', 'Arrival session', 'Depart session', 'Arrival transport', 'Arrival carrier',
                               'Arrival route num', 'Arrival date', 'Arrival time', 'Depart transport', 'Depart carrier',
                               'Depart route num', 'Depart date', 'Depart time', 'Note'])
      expect(csv.second).to eq(['Zimmerman, Ada', user.email, session_label, session_label, 'Airplane', 'Delta', 'DL123',
                                'Sunday, 06 Jul 2031', '02:30 PM', 'Train', 'Amtrak', '350', 'Sunday, 20 Jul 2031', '09:05 AM',
                                'Needs a shuttle'])
    end
  end

  describe 'GET /admin/travels/:id' do
    it 'renders arrival and departure panels' do
      get admin_travel_path(travel)

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include(admin_application_path(enrollment))
      expect(body).to include('Arrival')
      expect(body).to include('Departure')
      expect(body).to include('Sunday, 06 Jul 2031')
      expect(body).to include('09:05 AM')
      expect(body).to include('Needs a shuttle')
    end
  end

  describe 'new/create' do
    it 'offers active sessions and the transportation list on a new travel' do
      get new_admin_travel_path

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include("Zimmerman, Ada - #{user.email}")
      expect(body).to include(session_label)
      expect(body).to include('I am a daily MMSS commuter')
      expect(body).to include('type="time"')
      expect(body).to include('type="date"')
    end

    it 'creates a travel' do
      other = create(:enrollment, user: create(:user, :with_applicant_detail))
      params = { enrollment_id: other.id, arrival_session: session_label, depart_session: session_label, arrival_transport: 'Bus',
                 depart_transport: 'Bus', arrival_date: '2031-07-06', arrival_time: '10:15', depart_date: '2031-07-20', depart_time: '16:45' }

      expect { post admin_travels_path, params: { travel: params } }.to change(Travel, :count).by(1)

      created = Travel.last
      expect(created.arrival_time.strftime('%H:%M')).to eq('10:15')
      expect(response).to redirect_to(admin_travel_path(created))
    end

    it 're-renders with errors when invalid' do
      post admin_travels_path, params: { travel: { enrollment_id: enrollment.id, arrival_session: '', depart_session: session_label } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(CGI.unescapeHTML(response.body)).to include("Arrival session can't be blank")
    end
  end

  describe 'edit/update' do
    it "limits the session selects to the applicant's assigned sessions plus the persisted value" do
      assigned = create(:camp_occurrence, camp_configuration: session.camp_configuration, description: 'Session Assigned', active: true)
      create(:session_assignment, enrollment: enrollment, camp_occurrence: assigned)
      travel.update_columns(arrival_session: 'Old Session: June 01 to June 08')

      get edit_admin_travel_path(travel)

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include(assigned.description_with_month_and_day)
      expect(body).to include('<option selected="selected" value="Old Session: June 01 to June 08">')
      # Active-but-unassigned sessions are not offered when editing (as in ActiveAdmin): the active
      # session only appears as the persisted depart_session option.
      expect(body.scan(%(value="#{session_label}")).size).to eq(1)
      expect(body).to include('<option selected="selected" value="Train">Train</option>')
    end

    it 'updates the travel' do
      patch admin_travel_path(travel), params: { travel: { arrival_carrier: 'United', note: 'Updated' } }

      expect(response).to redirect_to(admin_travel_path(travel))
      travel.reload
      expect(travel.arrival_carrier).to eq('United')
      expect(travel.note).to eq('Updated')
    end
  end

  describe 'destroy and batch' do
    it 'destroys the travel' do
      expect { delete admin_travel_path(travel) }.to change(Travel, :count).by(-1)
      expect(response).to redirect_to(admin_travels_path)
    end

    it 'destroys the selected travels' do
      expect { post batch_admin_travels_path, params: { batch_action: 'destroy', ids: [travel.id] } }
        .to change(Travel, :count).by(-1)
    end
  end

  describe 'public routes' do
    it 'keeps the applicant travel pages and drops the admin-only index/destroy' do
      sign_out admin
      sign_in user

      get new_enrollment_travel_path(enrollment)
      expect(response).to have_http_status(:ok)

      get enrollment_travels_path(enrollment)
      expect(response).to have_http_status(:not_found)
      expect { delete enrollment_travel_path(enrollment, travel) }.not_to change(Travel, :count)
      expect(response).to have_http_status(:not_found)
    end
  end

  it 'requires an admin' do
    sign_out admin
    get admin_travels_path
    expect(response).to redirect_to(new_admin_session_path)
  end
end
