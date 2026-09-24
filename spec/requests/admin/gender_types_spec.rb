# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin gender types', type: :request do
  let(:admin) { create(:admin) }
  let!(:gender) { create(:gender, :non_binary) }

  before { sign_in admin }

  describe 'GET /admin/gender_types' do
    it 'lists gender types without filters' do
      get admin_gender_types_path

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('Non-binary')
      expect(body).not_to include('Filters')
      expect(body).to include('With selected:')
      expect(body).to include(edit_admin_gender_type_path(gender))
      expect(body).to include('Download CSV')
    end

    it 'sorts by name' do
      get admin_gender_types_path, params: { sort: 'name', direction: 'desc' }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('direction=asc')
    end

    it 'exports CSV' do
      get admin_gender_types_path(format: :csv)

      expect(response.media_type).to eq('text/csv')
      csv = CSV.parse(response.body)
      expect(csv.first).to eq(['Id', 'Name', 'Description', 'Created at', 'Updated at'])
      expect(csv.second[1]).to eq('Non-binary')
    end
  end

  describe 'GET /admin/gender_types/:id' do
    it 'renders the record' do
      get admin_gender_type_path(gender)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Gender Type ##{gender.id}")
      expect(response.body).to include('Non-binary')
    end
  end

  describe 'POST /admin/gender_types' do
    it 'creates a gender type' do
      expect { post admin_gender_types_path, params: { gender: { name: 'Agender', description: 'Agender' } } }
        .to change(Gender, :count).by(1)
      expect(response).to redirect_to(admin_gender_type_path(Gender.find_by!(name: 'Agender')))
    end

    it 're-renders with errors when the name is taken' do
      post admin_gender_types_path, params: { gender: { name: 'non-binary' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('Name has already been taken')
    end
  end

  describe 'PATCH /admin/gender_types/:id' do
    it 'updates the record' do
      patch admin_gender_type_path(gender), params: { gender: { description: 'Updated' } }

      expect(response).to redirect_to(admin_gender_type_path(gender))
      expect(gender.reload.description).to eq('Updated')
    end
  end

  describe 'DELETE /admin/gender_types/:id' do
    it 'destroys the record' do
      expect { delete admin_gender_type_path(gender) }.to change(Gender, :count).by(-1)
      expect(response).to redirect_to(admin_gender_types_path)
    end
  end

  describe 'POST /admin/gender_types/batch' do
    it 'destroys the selected records' do
      other = create(:gender)

      expect { post batch_admin_gender_types_path, params: { batch_action: 'destroy', ids: [gender.id, other.id] } }
        .to change(Gender, :count).by(-2)
      expect(flash[:notice]).to include('Deleted 2')
    end
  end

  it 'requires an admin' do
    sign_out admin
    get admin_gender_types_path
    expect(response).to redirect_to(new_admin_session_path)
  end
end
