# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin activities', type: :request do
  let(:admin) { create(:admin) }
  let(:camp) { create(:camp_configuration, :active, camp_year: 2031) }
  let(:session) { create(:camp_occurrence, camp_configuration: camp, description: 'Session Alpha', begin_date: Date.new(2031, 7, 1), end_date: Date.new(2031, 7, 8)) }
  let!(:activity) do
    create(:activity, camp_occurrence: session, description: 'Residential Stay', cost_cents: 50_000, date_occurs: Date.new(2031, 7, 2), active: true)
  end

  before { sign_in admin }

  describe 'GET /admin/activities' do
    it 'lists activities with session, cost, filters and batch actions' do
      get admin_activities_path

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('Residential Stay')
      expect(body).to include('$500')
      expect(body).to include(admin_session_configuration_path(session))
      expect(body).to include('Toggle active')
      expect(body).to include('Cost (cents)')
      expect(body).to include('Download CSV')
    end

    it 'filters by session, description, cost, date range and active' do
      other_session = create(:camp_occurrence, camp_configuration: camp, description: 'Session Beta', begin_date: Date.new(2031, 8, 1), end_date: Date.new(2031, 8, 8))
      other = create(:activity, camp_occurrence: other_session, description: 'Bowling', cost_cents: 1_500, date_occurs: Date.new(2031, 8, 3), active: false)
      stay_row = edit_admin_activity_path(activity)
      bowling_row = edit_admin_activity_path(other)

      get admin_activities_path, params: { q: { camp_occurrence_id: session.id } }
      expect(response.body).to include(stay_row)
      expect(response.body).not_to include(bowling_row)

      get admin_activities_path, params: { q: { description: 'Bowling' } }
      expect(response.body).to include(bowling_row)
      expect(response.body).not_to include(stay_row)

      get admin_activities_path, params: { q: { cost_cents: '1500' } }
      expect(response.body).to include(bowling_row)
      expect(response.body).not_to include(stay_row)

      get admin_activities_path, params: { q: { date_occurs_from: '2031-08-01', date_occurs_to: '2031-08-31' } }
      expect(response.body).to include(bowling_row)
      expect(response.body).not_to include(stay_row)

      get admin_activities_path, params: { q: { active: 'true' } }
      expect(response.body).to include(stay_row)
      expect(response.body).not_to include(bowling_row)
    end

    it 'sorts by session through the join' do
      get admin_activities_path, params: { sort: 'session', direction: 'asc' }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('direction=desc')
    end

    it 'exports CSV' do
      get admin_activities_path(format: :csv)

      expect(response.media_type).to eq('text/csv')
      csv = CSV.parse(response.body)
      expect(csv.first).to eq(['Id', 'Session', 'Description', 'Cost', 'Date occurs', 'Active', 'Created at', 'Updated at'])
      expect(csv.second[1..4]).to eq(['Session Alpha', 'Residential Stay', '$500.00', '2031-07-02'])
    end
  end

  describe 'GET /admin/activities/:id' do
    it 'renders attributes and comments' do
      get admin_activity_path(activity)

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('Residential Stay')
      expect(body).to include('Session Alpha')
      expect(body).to include('$500')
      expect(body).to include('Add a comment')
      expect(body).to include('resource_type" value="Activity"')
    end

    it 'accepts admin comments' do
      post admin_comments_path, params: { resource_type: 'Activity', resource_id: activity.id, admin_comment: { body: 'Bring linens' } },
                                headers: { 'HTTP_REFERER' => admin_activity_path(activity) }

      expect(response).to redirect_to(admin_activity_path(activity))
      expect(activity.admin_comments.pluck(:body)).to eq(['Bring linens'])
    end
  end

  describe 'GET /admin/activities/new' do
    it 'renders the form with the Residential Stay hint' do
      get new_admin_activity_path

      expect(response).to have_http_status(:ok)
      expect(CGI.unescapeHTML(response.body)).to include('please use "Residential Stay"')
      expect(response.body).to include('name="activity[camp_occurrence_id]"')
    end
  end

  describe 'POST /admin/activities' do
    it 'creates an activity with a money cost' do
      params = { camp_occurrence_id: session.id, description: 'Kayaking', cost: '45.00', date_occurs: '2031-07-04', active: '1' }

      expect { post admin_activities_path, params: { activity: params } }.to change(Activity, :count).by(1)

      created = Activity.find_by!(description: 'Kayaking')
      expect(created.cost_cents).to eq(4_500)
      expect(response).to redirect_to(admin_activity_path(created))
    end

    it 're-renders with errors when invalid' do
      post admin_activities_path, params: { activity: { camp_occurrence_id: session.id, description: '' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(CGI.unescapeHTML(response.body)).to include("Description can't be blank")
    end
  end

  describe 'PATCH /admin/activities/:id' do
    it 'updates the activity' do
      patch admin_activity_path(activity), params: { activity: { active: '0' } }

      expect(response).to redirect_to(admin_activity_path(activity))
      expect(activity.reload.active).to be(false)
    end
  end

  describe 'DELETE /admin/activities/:id' do
    it 'destroys the activity' do
      expect { delete admin_activity_path(activity) }.to change(Activity, :count).by(-1)
      expect(response).to redirect_to(admin_activities_path)
    end
  end

  describe 'POST /admin/activities/batch' do
    it 'toggles active' do
      post batch_admin_activities_path, params: { batch_action: 'toggle_active', ids: [activity.id] }

      expect(response).to redirect_to(admin_activities_path)
      expect(flash[:notice]).to include('Toggled active status for 1 activity')
      expect(activity.reload.active).to be(false)
    end

    it 'destroys the selected activities' do
      expect { post batch_admin_activities_path, params: { batch_action: 'destroy', ids: [activity.id] } }
        .to change(Activity, :count).by(-1)
    end
  end

  it 'requires an admin' do
    sign_out admin
    get admin_activities_path
    expect(response).to redirect_to(new_admin_session_path)
  end
end
