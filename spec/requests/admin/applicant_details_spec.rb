# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin applicant details', type: :request do
  let(:admin) { create(:admin) }
  let(:user) { create(:user, :with_applicant_detail) }
  let(:applicant_detail) { user.applicant_detail }
  let!(:enrollment) { create(:enrollment, :enrolled, user: user) }

  before do
    applicant_detail.update!(lastname: 'Zimmerman', firstname: 'Ada', city: 'Ann Arbor', diet_restrictions: 'Peanuts',
                             parentname: 'Grace Zimmerman', birthdate: Date.new(2009, 3, 14), us_citizen: true)
    sign_in admin
  end

  it 'requires an admin' do
    sign_out admin

    get admin_applicant_details_path

    expect(response).to redirect_to(new_admin_session_path)
  end

  describe 'GET /admin/applicant_details' do
    it 'lists applicants with scopes, filters, the ActiveAdmin columns and view/edit actions but no delete' do
      get admin_applicant_details_path

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('Zimmerman, Ada')
      expect(body).to include(user.email)
      expect(body).to include(admin_application_path(enrollment))
      expect(body).to include('Current camp enrolled')
      expect(body).to include('Application status')
      expect(body).to include(Gender.find(applicant_detail.gender).name)
      expect(body).to include(applicant_detail.formatted_demographic)
      expect(body).to include('Ann Arbor')
      expect(body).to include('Peanuts')
      expect(body).to include(edit_admin_applicant_detail_path(applicant_detail))
      expect(body).to include('New Applicant Detail')
      expect(body).to include('Download CSV')
      expect(body).to include('Last name (starts with)')
      expect(body).not_to include('With selected:')
      expect(body).not_to include('>Delete<')
    end

    it 'never turns URL options smuggled into the query string into off-site links' do
      get admin_applicant_details_path, params: { host: 'evil.example', protocol: 'https', port: 8443, script_name: '/x',
                                                  only_path: 'false', sort: 'fullname', scope: 'all', q: { lastname: 'Zim' } }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('evil.example')
      expect(response.body).not_to include('https://')
      expect(response.body).to include('href="/admin/applicant_details?')
      expect(response.body).to include('direction=desc')
      expect(response.body).to include('q%5Blastname%5D=Zim')
      expect(response.body).to include('scope=current_camp_enrolled')
    end

    it 'scopes to applicants enrolled in the current camp' do
      other = create(:user, :with_applicant_detail)
      other.applicant_detail.update!(lastname: 'Anderson')
      create(:enrollment, :application_complete, user: other)

      get admin_applicant_details_path
      expect(response.body).to include('Zimmerman')
      expect(response.body).to include('Anderson')

      get admin_applicant_details_path, params: { scope: 'current_camp_enrolled' }
      expect(response.body).to include('Zimmerman')
      expect(response.body).not_to include('Anderson')
      expect(response.body).to include('admin-tab-active')
    end

    it 'filters by gender, demographic, last name, citizenship, birthdate range, diet and parent name' do
      other_gender = create(:gender, name: 'Nonbinary')
      other_demographic = create(:demographic, name: 'Zeta Demographic')
      other = create(:user, :with_applicant_detail)
      other.applicant_detail.update!(lastname: 'Anderson', gender: other_gender.id.to_s, demographic: other_demographic,
                                     us_citizen: false, birthdate: Date.new(2007, 1, 1), diet_restrictions: 'Vegan',
                                     parentname: 'Pat Anderson')

      get admin_applicant_details_path, params: { q: { gender: other_gender.id } }
      expect(response.body).to include('Anderson')
      expect(response.body).not_to include('Zimmerman')
      expect(response.body).to include('1 active filter')

      get admin_applicant_details_path, params: { q: { demographic_id: other_demographic.id } }
      expect(response.body).to include('Anderson')
      expect(response.body).not_to include('Zimmerman')

      get admin_applicant_details_path, params: { q: { lastname: 'Zim' } }
      expect(response.body).to include('Zimmerman')
      expect(response.body).not_to include('Anderson')

      get admin_applicant_details_path, params: { q: { us_citizen: 'false' } }
      expect(response.body).to include('Anderson')
      expect(response.body).not_to include('Zimmerman')

      get admin_applicant_details_path, params: { q: { birthdate_from: '2009-01-01', birthdate_to: '2009-12-31' } }
      expect(response.body).to include('Zimmerman')
      expect(response.body).not_to include('Anderson')

      get admin_applicant_details_path, params: { q: { diet_restrictions: 'vegan' } }
      expect(response.body).to include('Anderson')
      expect(response.body).not_to include('Zimmerman')

      get admin_applicant_details_path, params: { q: { parentname: 'Grace' } }
      expect(response.body).to include('Zimmerman')
      expect(response.body).not_to include('Anderson')
    end

    it 'sorts by an allowed column and ignores unknown ones' do
      get admin_applicant_details_path, params: { sort: 'email', direction: 'asc' }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('direction=desc')

      get admin_applicant_details_path, params: { sort: 'drop table', direction: 'asc' }
      expect(response).to have_http_status(:ok)
    end

    it 'renders pagination links when there is more than one page' do
      32.times { create(:user, :with_applicant_detail) }

      get admin_applicant_details_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Showing <span class="font-medium">1</span>–<span class="font-medium">30</span>')
      expect(response.body).to include('of <span class="font-medium">33</span>')
      expect(response.body).to include('href="/admin/applicant_details?page=2"')
      expect(response.body).to include('rel="next"')

      get admin_applicant_details_path, params: { page: 2, limit: 1, scope: 'all' }
      expect(response.body).to include('Showing <span class="font-medium">2</span>–<span class="font-medium">2</span>')
      expect(response.body).to include('rel="prev"')
    end

    it 'exports the ActiveAdmin CSV column set' do
      get admin_applicant_details_path(format: :csv)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/csv')
      expect(response.headers['Content-Disposition']).to include('MMSS-applicant_details-')
      csv = CSV.parse(response.body)
      expect(csv.first).to eq(
        ['Lastname', 'Firstname', 'email', 'demographic', 'Us citizen', 'Birthdate', 'Diet restrictions', 'Shirt size',
         'Address1', 'Address2', 'City', 'State', 'State non us', 'Postalcode', 'Country', 'Phone', 'Parentname',
         'Parentphone', 'Parentworkphone', 'Parentemail', 'Created at', 'Updated at']
      )
      row = csv.second
      expect(row[0..2]).to eq(['Zimmerman', 'Ada', user.email])
      expect(row[3]).to eq(applicant_detail.formatted_demographic)
      expect(row[4]).to eq('true')
      expect(row[5]).to eq('2009-03-14')
      expect(row[16]).to eq('Grace Zimmerman')
    end
  end

  describe 'GET /admin/applicant_details/:id' do
    it 'renders the applications panel, parent panel, details sidebar and comments' do
      get admin_applicant_detail_path(applicant_detail)

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('Zimmerman, Ada')
      expect(body).to include(admin_application_path(enrollment))
      expect(body).to include("#{enrollment.campyear} — Application ##{enrollment.id}")
      %w[Applications Parent\ /\ guardian Details Comments].each { |panel| expect(body).to include(panel) }
      expect(body).to include('Grace Zimmerman')
      expect(body).to include('Add a comment')
      expect(body).not_to include('>Delete<')
    end
  end

  describe 'GET /admin/applicant_details/new' do
    it 'lists only users without applicant details in the user select' do
      orphan = create(:user)

      get new_admin_applicant_detail_path

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('name="applicant_detail[user_id]"')
      expect(body).to include(%(<option value="#{orphan.id}">#{orphan.email}</option>))
      expect(body).not_to include(%(<option value="#{user.id}">#{user.email}</option>))
      expect(body).to include('data-controller="demographic-other"')
      expect(body).to include('id="applicant_detail_demographic"')
      expect(body).to include('name="applicant_detail[state]"')
      expect(body).to include('name="applicant_detail[parentcountry]"')
    end
  end

  describe 'POST /admin/applicant_details' do
    let(:orphan) { create(:user) }
    let(:valid_params) do
      attributes_for(:applicant_detail).except(:ensure_demographic).merge(
        user_id: orphan.id, gender: Gender.first.id.to_s, demographic_id: Demographic.first.id,
        firstname: 'New', lastname: 'Applicant', parentemail: 'parent-new@example.com', country: 'US', parentcountry: 'US'
      )
    end

    it 'creates the applicant detail for the chosen user' do
      expect do
        post admin_applicant_details_path, params: { applicant_detail: valid_params }
      end.to change(ApplicantDetail, :count).by(1)

      created = orphan.reload.applicant_detail
      expect(response).to redirect_to(admin_applicant_detail_path(created))
      expect(created.full_name).to eq('Applicant, New')
      follow_redirect!
      expect(response.body).to include('Applicant detail was successfully created.')
    end

    it 're-renders the form with errors when invalid' do
      post admin_applicant_details_path, params: { applicant_detail: valid_params.merge(phone: 'nope') }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('Phone number format is incorrect')
    end
  end

  describe 'GET /admin/applicant_details/:id/edit' do
    it 'renders the form without a user select' do
      get edit_admin_applicant_detail_path(applicant_detail)

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('name="applicant_detail[lastname]"')
      expect(body).not_to include('name="applicant_detail[user_id]"')
      expect(body).to include(user.email)
      expect(body).to include(%(<option selected="selected" value="#{applicant_detail.gender}">))
    end
  end

  describe 'PATCH /admin/applicant_details/:id' do
    it 'updates attributes and never re-homes the record to another user' do
      other = create(:user)

      patch admin_applicant_detail_path(applicant_detail),
            params: { applicant_detail: { city: 'Detroit', shirt_size: 'Large', user_id: other.id } }

      expect(response).to redirect_to(admin_applicant_detail_path(applicant_detail))
      applicant_detail.reload
      expect(applicant_detail.city).to eq('Detroit')
      expect(applicant_detail.shirt_size).to eq('Large')
      expect(applicant_detail.user).to eq(user)
      follow_redirect!
      expect(response.body).to include('Applicant detail was successfully updated.')
    end

    it 'clears demographic_other when the demographic is not Other' do
      other_demographic = Demographic.find_or_create_by!(name: 'Other') { |d| d.description = 'Other'; d.protected = true }
      applicant_detail.update!(demographic: other_demographic, demographic_other: 'Custom')

      patch admin_applicant_detail_path(applicant_detail),
            params: { applicant_detail: { demographic_id: Demographic.where.not(id: other_demographic.id).first.id } }

      expect(response).to redirect_to(admin_applicant_detail_path(applicant_detail))
      expect(applicant_detail.reload.demographic_other).to be_nil
    end

    it 're-renders the form with errors when invalid' do
      patch admin_applicant_detail_path(applicant_detail), params: { applicant_detail: { lastname: '' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(CGI.unescapeHTML(response.body)).to include("Lastname can't be blank")
    end
  end

  describe 'destroy' do
    it 'has no route in the admin' do
      delete "/admin/applicant_details/#{applicant_detail.id}"

      expect(response).not_to have_http_status(:ok)
      expect(ApplicantDetail.exists?(applicant_detail.id)).to be(true)
    end
  end

  describe 'public routes' do
    before do
      sign_out admin
      sign_in user
    end

    it 'no longer has the admin-only index and destroy' do
      get '/applicant_details'
      expect(response).to have_http_status(:not_found)

      delete "/applicant_details/#{applicant_detail.id}"
      expect(response).to have_http_status(:not_found)

      expect(ApplicantDetail.exists?(applicant_detail.id)).to be(true)
    end

    it 'keeps the applicant-facing edit form' do
      get edit_applicant_detail_path(applicant_detail)

      expect(response).to have_http_status(:ok)
    end
  end
end
