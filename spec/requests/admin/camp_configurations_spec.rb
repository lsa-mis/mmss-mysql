# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin camp configurations', type: :request do
  let(:admin) { create(:admin) }
  let!(:camp) do
    create(:camp_configuration, :active, camp_year: 2031, application_open: Date.new(2031, 1, 10),
                                         offer_letter: 'Welcome to camp 2031', application_fee_cents: 12_550)
  end

  before { sign_in admin }

  describe 'GET /admin/camp_configurations' do
    it 'lists camps with filters, batch actions, money and CSV link' do
      get admin_camp_configurations_path

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('2031')
      expect(body).to include('$125.50')
      expect(body).to include('Application open')
      expect(body).to include('With selected:')
      expect(body).to include('Download CSV')
      expect(body).to include(edit_admin_camp_configuration_path(camp))
    end

    it 'filters by date range and boolean' do
      other = create(:camp_configuration, camp_year: 2032, application_open: Date.new(2032, 1, 10), active: false)
      camp_row = edit_admin_camp_configuration_path(camp)
      other_row = edit_admin_camp_configuration_path(other)

      get admin_camp_configurations_path, params: { q: { application_open_from: '2031-01-01', application_open_to: '2031-12-31' } }
      expect(response.body).to include(camp_row)
      expect(response.body).not_to include(other_row)

      get admin_camp_configurations_path, params: { q: { active: 'false' } }
      expect(response.body).to include(other_row)
      expect(response.body).not_to include(camp_row)
    end

    it 'sorts by allowed columns' do
      get admin_camp_configurations_path, params: { sort: 'application_fee', direction: 'asc' }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('direction=desc')

      get admin_camp_configurations_path, params: { sort: 'bogus' }
      expect(response).to have_http_status(:ok)
    end

    it 'exports CSV with id and content columns' do
      get admin_camp_configurations_path(format: :csv)

      expect(response.media_type).to eq('text/csv')
      csv = CSV.parse(response.body)
      expect(csv.first).to eq(
        ['Id', 'Camp year', 'Application open', 'Application close', 'Priority', 'Application materials due',
         'Camper acceptance due', 'Active', 'Offer letter', 'Student packet url', 'Application fee', 'Reject letter',
         'Waitlist letter', 'Application fee required', 'Created at', 'Updated at']
      )
      expect(csv.second[1]).to eq('2031')
      expect(csv.second[10]).to eq('$125.50')
    end
  end

  describe 'GET /admin/camp_configurations/:id' do
    it 'renders the attributes, letters and sessions' do
      session = create(:camp_occurrence, camp_configuration: camp, description: 'Session Alpha')

      get admin_camp_configuration_path(camp)

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('Camp Configuration 2031')
      expect(body).to include('Offer Letter Text')
      expect(body).to include('Welcome to camp 2031')
      expect(body).to include('Rejection Letter Text')
      expect(body).to include('Wait list Letter Text')
      expect(body).to include('Student Packet URL for campers who accept their offer')
      expect(body).to include(admin_session_configuration_path(session))
      expect(body).not_to include('Add a comment')
    end

    it 'only links the student packet URL when it is a web URL' do
      camp.update!(student_packet_url: 'https://example.com/packet.pdf')
      get admin_camp_configuration_path(camp)
      expect(response.body).to include('href="https://example.com/packet.pdf"')

      camp.update_columns(student_packet_url: 'javascript:alert(1)')
      get admin_camp_configuration_path(camp)
      expect(response.body).not_to include('href="javascript:')
      expect(response.body).to include('javascript:alert(1)')
    end
  end

  describe 'GET /admin/camp_configurations/new' do
    it 'copies the letters and fee from the last camp and warns about it' do
      get new_admin_camp_configuration_path

      expect(response).to have_http_status(:ok)
      body = CGI.unescapeHTML(response.body)
      expect(body).to include("Each letter's text and camp fee were copied from previous camp")
      expect(body).to include('Welcome to camp 2031')
      expect(body).to include('value="125.50"')
      expect(body).not_to include('value="2031"')
    end

    it 'renders an empty form when no camp exists yet' do
      CampConfiguration.delete_all

      get new_admin_camp_configuration_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('were copied from previous camp')
    end
  end

  describe 'POST /admin/camp_configurations' do
    it 'creates a camp' do
      attributes = attributes_for(:camp_configuration, camp_year: 2040).merge(application_fee: '99.99')
      attributes.delete(:application_fee_cents)

      expect { post admin_camp_configurations_path, params: { camp_configuration: attributes } }
        .to change(CampConfiguration, :count).by(1)

      created = CampConfiguration.find_by!(camp_year: 2040)
      expect(created.application_fee_cents).to eq(9_999)
      expect(response).to redirect_to(admin_camp_configuration_path(created))
    end

    it 're-renders with errors when invalid' do
      post admin_camp_configurations_path, params: { camp_configuration: { camp_year: '' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(CGI.unescapeHTML(response.body)).to include("Camp year can't be blank")
    end
  end

  describe 'PATCH /admin/camp_configurations/:id' do
    it 'updates the camp' do
      patch admin_camp_configuration_path(camp), params: { camp_configuration: { student_packet_url: 'https://example.com/packet', application_fee_required: '0' } }

      expect(response).to redirect_to(admin_camp_configuration_path(camp))
      camp.reload
      expect(camp.student_packet_url).to eq('https://example.com/packet')
      expect(camp.application_fee_required).to be(false)
    end

    it 'rejects a student packet URL that is not http(s)' do
      patch admin_camp_configuration_path(camp), params: { camp_configuration: { student_packet_url: 'javascript:alert(1)' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('must start with http:// or https://')
      expect(camp.reload.student_packet_url).to be_nil
    end

    it 'rejects a second active camp' do
      other = create(:camp_configuration, camp_year: 2033, active: false)

      patch admin_camp_configuration_path(other), params: { camp_configuration: { active: '1' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('cannot have another active camp')
    end
  end

  describe 'DELETE /admin/camp_configurations/:id' do
    it 'destroys the camp' do
      expect { delete admin_camp_configuration_path(camp) }.to change(CampConfiguration, :count).by(-1)
      expect(response).to redirect_to(admin_camp_configurations_path)
    end
  end

  describe 'POST /admin/camp_configurations/batch' do
    it 'destroys the selected camps' do
      other = create(:camp_configuration, camp_year: 2034)

      expect { post batch_admin_camp_configurations_path, params: { batch_action: 'destroy', ids: [camp.id, other.id] } }
        .to change(CampConfiguration, :count).by(-2)
      expect(flash[:notice]).to include('Deleted 2')
    end
  end

  it 'requires an admin' do
    sign_out admin
    get admin_camp_configurations_path
    expect(response).to redirect_to(new_admin_session_path)
  end
end
