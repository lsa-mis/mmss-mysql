# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin demographics', type: :request do
  let(:admin) { create(:admin) }
  let!(:demographic) { create(:demographic, name: 'Hispanic Or Latino', description: 'Hispanic or Latino') }
  let!(:protected_demographic) { create(:demographic, :other) }

  before { sign_in admin }

  describe 'GET /admin/demographics' do
    it 'lists demographics without filters and hides edit/delete for protected records' do
      get admin_demographics_path

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('Hispanic Or Latino')
      expect(body).to include('Other')
      expect(body).not_to include('Filters')
      expect(body).to include('With selected:')
      expect(body).to include(edit_admin_demographic_path(demographic))
      expect(body).not_to include(edit_admin_demographic_path(protected_demographic))
      expect(body).to include('Download CSV')
    end

    it 'sorts by name' do
      get admin_demographics_path, params: { sort: 'name', direction: 'desc' }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('direction=asc')
    end

    it 'exports CSV' do
      get admin_demographics_path(format: :csv)

      expect(response.media_type).to eq('text/csv')
      csv = CSV.parse(response.body)
      expect(csv.first).to eq(['Id', 'Name', 'Description', 'Protected', 'Created at', 'Updated at'])
      expect(csv.map { |row| row[1] }).to include('Hispanic Or Latino', 'Other')
    end
  end

  describe 'GET /admin/demographics/:id' do
    it 'renders the record and flags protected ones' do
      get admin_demographic_path(protected_demographic)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('This demographic record is protected and cannot be modified.')
      expect(response.body).not_to include(edit_admin_demographic_path(protected_demographic))

      get admin_demographic_path(demographic)
      expect(response.body).to include(edit_admin_demographic_path(demographic))
    end
  end

  describe 'GET /admin/demographics/:id/edit' do
    it 'renders a read-only panel for protected records and a form otherwise' do
      get edit_admin_demographic_path(protected_demographic)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Protected Record')
      expect(response.body).not_to include('name="demographic[name]"')

      get edit_admin_demographic_path(demographic)
      expect(response.body).to include('name="demographic[name]"')
    end
  end

  describe 'POST /admin/demographics' do
    it 'creates a demographic (name is title-cased)' do
      expect { post admin_demographics_path, params: { demographic: { name: 'pacific islander', description: 'Pacific Islander' } } }
        .to change(Demographic, :count).by(1)

      created = Demographic.find_by!(description: 'Pacific Islander')
      expect(created.name).to eq('Pacific Islander')
      expect(response).to redirect_to(admin_demographic_path(created))
    end

    it 're-renders with errors when invalid' do
      post admin_demographics_path, params: { demographic: { name: 'Bad, Name!', description: '' } }

      expect(response).to have_http_status(:unprocessable_content)
      body = CGI.unescapeHTML(response.body)
      expect(body).to include('cannot contain punctuation')
      expect(body).to include("Description can't be blank")
    end
  end

  describe 'PATCH /admin/demographics/:id' do
    it 'updates a modifiable record' do
      patch admin_demographic_path(demographic), params: { demographic: { description: 'Updated description' } }

      expect(response).to redirect_to(admin_demographic_path(demographic))
      expect(demographic.reload.description).to eq('Updated description')
    end

    it 'refuses to modify protected records' do
      patch admin_demographic_path(protected_demographic), params: { demographic: { description: 'Hacked' } }

      expect(response).to redirect_to(admin_demographic_path(protected_demographic))
      expect(flash[:error]).to eq('Cannot modify protected demographic records')
      expect(protected_demographic.reload.description).to eq('Other demographic option')
    end
  end

  describe 'DELETE /admin/demographics/:id' do
    it 'destroys a modifiable record' do
      expect { delete admin_demographic_path(demographic) }.to change(Demographic, :count).by(-1)
      expect(response).to redirect_to(admin_demographics_path)
    end

    it 'refuses to delete protected records' do
      expect { delete admin_demographic_path(protected_demographic) }.not_to change(Demographic, :count)
      expect(response).to redirect_to(admin_demographic_path(protected_demographic))
      expect(flash[:error]).to eq('Cannot delete protected demographic records')
    end
  end

  describe 'POST /admin/demographics/batch' do
    it 'deletes only the unprotected records' do
      expect { post batch_admin_demographics_path, params: { batch_action: 'destroy', ids: [demographic.id, protected_demographic.id] } }
        .to change(Demographic, :count).by(-1)

      expect(Demographic.exists?(protected_demographic.id)).to be(true)
      expect(flash[:notice]).to include('Deleted 1')
    end
  end

  it 'requires an admin' do
    sign_out admin
    get admin_demographics_path
    expect(response).to redirect_to(new_admin_session_path)
  end
end
