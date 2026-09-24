# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin campnotes', type: :request do
  let(:admin) { create(:admin) }
  let!(:note) do
    create(:campnote, note: 'Applications open soon', notetype: 'notice',
                      opendate: Time.zone.local(2031, 1, 1, 9), closedate: Time.zone.local(2031, 1, 31, 17))
  end

  before { sign_in admin }

  describe 'GET /admin/campnotes' do
    it 'lists notes with type badges, filters and batch actions' do
      get admin_campnotes_path

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('Applications open soon')
      expect(body).to include('admin-badge-blue">notice')
      expect(body).to include('Visible now')
      expect(body).to include('Note type')
      expect(body).to include('With selected:')
      expect(body).to include('Download CSV')
    end

    it 'filters by note text, type and open date range' do
      other = create(:campnote, note: 'Site maintenance tonight', notetype: 'alert',
                                opendate: Time.zone.local(2032, 3, 1), closedate: Time.zone.local(2032, 3, 2))
      note_row = edit_admin_campnote_path(note)
      other_row = edit_admin_campnote_path(other)

      get admin_campnotes_path, params: { q: { note: 'maintenance' } }
      expect(response.body).to include(other_row)
      expect(response.body).not_to include(note_row)

      get admin_campnotes_path, params: { q: { notetype: 'notice' } }
      expect(response.body).to include(note_row)
      expect(response.body).not_to include(other_row)

      get admin_campnotes_path, params: { q: { opendate_from: '2032-01-01', opendate_to: '2032-12-31' } }
      expect(response.body).to include(other_row)
      expect(response.body).not_to include(note_row)
    end

    it 'sorts by allowed columns' do
      get admin_campnotes_path, params: { sort: 'closedate', direction: 'asc' }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('direction=desc')
    end

    it 'exports CSV' do
      get admin_campnotes_path(format: :csv)

      expect(response.media_type).to eq('text/csv')
      csv = CSV.parse(response.body)
      expect(csv.first).to eq(['Id', 'Note', 'Opendate', 'Closedate', 'Notetype', 'Created at', 'Updated at'])
      expect(csv.second[1]).to eq('Applications open soon')
      expect(csv.second[4]).to eq('notice')
    end
  end

  describe 'GET /admin/campnotes/:id' do
    it 'renders the note and a preview' do
      get admin_campnote_path(note)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Campnote ##{note.id}")
      expect(response.body).to include('Preview')
      expect(response.body).to include('Applications open soon')
      expect(response.body).not_to include('Add a comment')
    end
  end

  describe 'POST /admin/campnotes' do
    it 'creates a note' do
      params = { note: 'Priority deadline is Friday', notetype: 'alert', opendate: '2033-04-01T08:00', closedate: '2033-04-05T18:00' }

      expect { post admin_campnotes_path, params: { campnote: params } }.to change(Campnote, :count).by(1)
      expect(response).to redirect_to(admin_campnote_path(Campnote.find_by!(note: 'Priority deadline is Friday')))
    end

    it 're-renders with errors when the dates overlap another note' do
      params = { note: 'Overlap', notetype: 'alert', opendate: '2031-01-15T08:00', closedate: '2031-01-16T18:00' }

      post admin_campnotes_path, params: { campnote: params }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('not available')
    end
  end

  describe 'PATCH /admin/campnotes/:id' do
    it 'updates the note' do
      patch admin_campnote_path(note), params: { campnote: { note: 'Applications are open', notetype: 'alert' } }

      expect(response).to redirect_to(admin_campnote_path(note))
      note.reload
      expect(note.note).to eq('Applications are open')
      expect(note.notetype).to eq('alert')
    end

    it 'rejects a close date before the open date' do
      patch admin_campnote_path(note), params: { campnote: { closedate: '2030-12-31T00:00' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('must be after the start date')
    end
  end

  describe 'DELETE /admin/campnotes/:id' do
    it 'destroys the note' do
      expect { delete admin_campnote_path(note) }.to change(Campnote, :count).by(-1)
      expect(response).to redirect_to(admin_campnotes_path)
    end
  end

  describe 'POST /admin/campnotes/batch' do
    it 'destroys the selected notes' do
      expect { post batch_admin_campnotes_path, params: { batch_action: 'destroy', ids: [note.id] } }
        .to change(Campnote, :count).by(-1)
      expect(flash[:notice]).to include('Deleted 1')
    end
  end

  it 'requires an admin' do
    sign_out admin
    get admin_campnotes_path
    expect(response).to redirect_to(new_admin_session_path)
  end
end
