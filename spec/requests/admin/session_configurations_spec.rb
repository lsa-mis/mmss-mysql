# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin session configurations', type: :request do
  let(:admin) { create(:admin) }
  let(:camp) { create(:camp_configuration, :active, camp_year: 2031) }
  let!(:session) do
    create(:camp_occurrence, camp_configuration: camp, description: 'Session Alpha', cost_cents: 250_000,
                             begin_date: Date.new(2031, 7, 1), end_date: Date.new(2031, 7, 8), active: true)
  end

  before { sign_in admin }

  describe 'GET /admin/session_configurations' do
    it 'lists sessions with camp year, cost, filters and batch actions' do
      get admin_session_configurations_path

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('Session Alpha')
      expect(body).to include('$2,500')
      expect(body).to include(admin_camp_configuration_path(camp))
      expect(body).to include('Toggle active')
      expect(body).to include('Download CSV')
    end

    it 'filters by camp, description select, date range and active' do
      other_camp = create(:camp_configuration, camp_year: 2032)
      other = create(:camp_occurrence, camp_configuration: other_camp, description: 'Session Beta',
                                       begin_date: Date.new(2032, 7, 1), end_date: Date.new(2032, 7, 8), active: false)
      alpha_row = edit_admin_session_configuration_path(session)
      beta_row = edit_admin_session_configuration_path(other)

      get admin_session_configurations_path, params: { q: { camp_configuration_id: camp.id } }
      expect(response.body).to include(alpha_row)
      expect(response.body).not_to include(beta_row)

      get admin_session_configurations_path, params: { q: { description: 'Session Beta' } }
      expect(response.body).to include(beta_row)
      expect(response.body).not_to include(alpha_row)

      get admin_session_configurations_path, params: { q: { begin_date_from: '2032-01-01' } }
      expect(response.body).to include(beta_row)
      expect(response.body).not_to include(alpha_row)

      get admin_session_configurations_path, params: { q: { active: 'true' } }
      expect(response.body).to include(alpha_row)
      expect(response.body).not_to include(beta_row)
    end

    it 'sorts by camp year through the join' do
      get admin_session_configurations_path, params: { sort: 'camp_year', direction: 'asc' }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('direction=desc')
    end

    it 'exports CSV' do
      get admin_session_configurations_path(format: :csv)

      expect(response.media_type).to eq('text/csv')
      csv = CSV.parse(response.body)
      expect(csv.first).to eq(['Id', 'Camp year', 'Description', 'Cost', 'Begin date', 'End date', 'Active', 'Created at', 'Updated at'])
      expect(csv.second[1..3]).to eq(['2031', 'Session Alpha', '$2,500.00'])
    end
  end

  describe 'GET /admin/session_configurations/:id' do
    it 'renders the attributes and comments' do
      get admin_session_configuration_path(session)

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('Session Alpha')
      expect(body).to include('Camp Year')
      expect(body).to include('$2,500')
      expect(body).to include('Add a comment')
      expect(body).to include('resource_type" value="CampOccurrence"')
    end

    it 'accepts admin comments' do
      post admin_comments_path, params: { resource_type: 'CampOccurrence', resource_id: session.id, admin_comment: { body: 'Dorm check-in at 2pm' } },
                                headers: { 'HTTP_REFERER' => admin_session_configuration_path(session) }

      expect(response).to redirect_to(admin_session_configuration_path(session))
      expect(session.admin_comments.pluck(:body)).to eq(['Dorm check-in at 2pm'])
    end
  end

  describe 'POST /admin/session_configurations' do
    it 'creates a session with a money cost' do
      params = { camp_configuration_id: camp.id, description: 'Session Gamma', begin_date: '2031-08-01', end_date: '2031-08-08',
                 active: '1', cost: '1234.56' }

      expect { post admin_session_configurations_path, params: { camp_occurrence: params } }.to change(CampOccurrence, :count).by(1)

      created = CampOccurrence.find_by!(description: 'Session Gamma')
      expect(created.cost_cents).to eq(123_456)
      expect(response).to redirect_to(admin_session_configuration_path(created))
    end

    it 're-renders with errors when invalid' do
      post admin_session_configurations_path, params: { camp_occurrence: { description: '', camp_configuration_id: camp.id } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(CGI.unescapeHTML(response.body)).to include("Description can't be blank")
    end
  end

  describe 'PATCH /admin/session_configurations/:id' do
    it 'updates the session' do
      patch admin_session_configuration_path(session), params: { camp_occurrence: { description: 'Session Alpha Prime' } }

      expect(response).to redirect_to(admin_session_configuration_path(session))
      expect(session.reload.description).to eq('Session Alpha Prime')
    end
  end

  describe 'DELETE /admin/session_configurations/:id' do
    it 'destroys the session' do
      expect { delete admin_session_configuration_path(session) }.to change(CampOccurrence, :count).by(-1)
      expect(response).to redirect_to(admin_session_configurations_path)
    end
  end

  describe 'POST /admin/session_configurations/batch' do
    it 'toggles active on the selected sessions' do
      inactive = create(:camp_occurrence, camp_configuration: camp, active: false)

      post batch_admin_session_configurations_path, params: { batch_action: 'toggle_active', ids: [session.id, inactive.id] }

      expect(response).to redirect_to(admin_session_configurations_path)
      expect(flash[:notice]).to include('Toggled active status for 2')
      expect(session.reload.active).to be(false)
      expect(inactive.reload.active).to be(true)
    end

    it 'destroys the selected sessions' do
      expect { post batch_admin_session_configurations_path, params: { batch_action: 'destroy', ids: [session.id] } }
        .to change(CampOccurrence, :count).by(-1)
    end
  end

  it 'requires an admin' do
    sign_out admin
    get admin_session_configurations_path
    expect(response).to redirect_to(new_admin_session_path)
  end
end
