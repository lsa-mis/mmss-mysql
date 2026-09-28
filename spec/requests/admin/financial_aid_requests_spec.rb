# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin financial aid requests', type: :request do
  let(:admin) { create(:admin) }
  let(:user) { create(:user, :with_applicant_detail) }
  let!(:enrollment) { create(:enrollment, :accepted, user: user, partner_program: 'Partner X') }
  let!(:financial_aid) do
    create(:financial_aid, :pending, enrollment: enrollment, amount_cents: 12_550, source: 'Grant', note: 'Needs help with tuition',
                                     adjusted_gross_income: 52_000, payments_deadline: Date.new(2030, 5, 1))
  end

  before do
    user.applicant_detail.update!(lastname: 'Zimmerman', firstname: 'Ada', country: 'CA', us_citizen: false)
    sign_in admin
  end

  it 'requires an admin' do
    sign_out admin

    get admin_financial_aid_requests_path

    expect(response).to redirect_to(new_admin_session_path)
  end

  describe 'GET /admin/financial_aid_requests' do
    it 'lists current camp requests with scopes, filters, batch actions and the ActiveAdmin columns' do
      get admin_financial_aid_requests_path

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('Zimmerman, Ada')
      expect(body).to include(user.email)
      expect(body).to include('Current camp requests')
      expect(body).to include('$52,000.00')
      expect(body).to include('$125.50')
      expect(body).to include('Grant')
      expect(body).to include('Needs help with tuition')
      expect(body).to include('pending')
      expect(body).to include('With selected:')
      expect(body).to include(edit_admin_financial_aid_request_path(financial_aid))
      expect(body).to include('New Financial Aid Request')
      expect(body).to include('Download CSV')
      expect(body).to include('Supporting Doc')
    end

    it 'never turns URL options smuggled into the query string into off-site links' do
      get admin_financial_aid_requests_path, params: { host: 'evil.example', protocol: 'https', port: 8443, script_name: '/x',
                                                       only_path: 'false', sort: 'status', scope: 'all', q: { status: 'pending' } }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('evil.example')
      expect(response.body).not_to include('https://')
      expect(response.body).to include('href="/admin/financial_aid_requests?')
      expect(response.body).to include('direction=asc')
      expect(response.body).to include('q%5Bstatus%5D=pending')
      expect(response.body).to include('scope=current_camp_requests')
    end

    it 'scopes to the current camp by default and shows everything under "all"' do
      old_enrollment = create(:enrollment, :accepted, user: create(:user, :with_applicant_detail), campyear: 1999)
      old_enrollment.applicant_detail.update!(lastname: 'Oldtimer')
      create(:financial_aid, :pending, enrollment: old_enrollment)

      get admin_financial_aid_requests_path
      expect(response.body).to include('Zimmerman')
      expect(response.body).not_to include('Oldtimer')

      get admin_financial_aid_requests_path, params: { scope: 'all' }
      expect(response.body).to include('Zimmerman')
      expect(response.body).to include('Oldtimer')
      expect(response.body).to include('admin-tab-active')
    end

    it 'filters by enrollment, status and source' do
      other = create(:enrollment, :accepted, user: create(:user, :with_applicant_detail))
      other.applicant_detail.update!(lastname: 'Anderson')
      other_aid = create(:financial_aid, enrollment: other, status: 'awarded', source: 'Scholarship', amount_cents: 5000,
                                         payments_deadline: Date.new(2030, 6, 1))

      # The enrollment filter select lists every current-camp applicant, so assert on table rows.
      mine = %(id="financial_aid_#{financial_aid.id}")
      theirs = %(id="financial_aid_#{other_aid.id}")

      get admin_financial_aid_requests_path, params: { q: { enrollment_id: enrollment.id } }
      expect(response.body).to include(mine)
      expect(response.body).not_to include(theirs)
      expect(response.body).to include('1 active filter')

      get admin_financial_aid_requests_path, params: { q: { status: 'awarded' } }
      expect(response.body).to include(theirs)
      expect(response.body).not_to include(mine)

      get admin_financial_aid_requests_path, params: { q: { source: 'Grant' } }
      expect(response.body).to include(mine)
      expect(response.body).not_to include(theirs)
    end

    it 'sorts by an allowed column and ignores unknown ones' do
      get admin_financial_aid_requests_path, params: { sort: 'enrollment', direction: 'asc' }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('direction=desc')

      get admin_financial_aid_requests_path, params: { sort: 'amount', direction: 'desc' }
      expect(response).to have_http_status(:ok)

      get admin_financial_aid_requests_path, params: { sort: 'drop table', direction: 'asc' }
      expect(response).to have_http_status(:ok)
    end

    it 'renders pagination links when there is more than one page' do
      32.times { create(:financial_aid, :pending, enrollment: create(:enrollment, :accepted, user: create(:user, :with_applicant_detail))) }

      get admin_financial_aid_requests_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Showing <span class="font-medium">1</span>–<span class="font-medium">30</span>')
      expect(response.body).to include('of <span class="font-medium">33</span>')
      expect(response.body).to include('href="/admin/financial_aid_requests?page=2"')
      expect(response.body).to include('rel="next"')

      get admin_financial_aid_requests_path, params: { page: 2, limit: 1 }
      expect(response.body).to include('Showing <span class="font-medium">2</span>–<span class="font-medium">2</span>')
      expect(response.body).to include('rel="prev"')
    end

    it 'exports the ActiveAdmin CSV column set with formatted money' do
      get admin_financial_aid_requests_path(format: :csv)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/csv')
      expect(response.headers['Content-Disposition']).to include('MMSS-financial_aid_requests-')
      csv = CSV.parse(response.body)
      expect(csv.first).to eq(
        ['First Name', 'Last Name', 'email', 'Residency Country', 'US Citizenship', 'Partner', 'Offer Status', 'FinAid Status',
         'Funding Amount', 'Funding Source', 'AGI', 'Updated at']
      )
      row = csv.second
      expect(row[0..7]).to eq(['Ada', 'Zimmerman', user.email, 'CA', 'false', 'Partner X', 'accepted', 'pending'])
      expect(row[8]).to eq('$125.50')
      expect(row[9]).to eq('Grant')
      expect(row[10]).to eq('$52,000.00')
    end

    it 'leaves the AGI blank in the CSV when it was not reported' do
      financial_aid.update_columns(adjusted_gross_income: nil)

      get admin_financial_aid_requests_path(format: :csv)

      expect(CSV.parse(response.body).second[10]).to be_nil
    end
  end

  describe 'GET /admin/financial_aid_requests/:id' do
    it 'renders the request, the balance due from PaymentState and comments' do
      create(:session_assignment, :accepted, enrollment: enrollment, camp_occurrence: CampOccurrence.active.first)
      expected = PaymentState.new(enrollment).balance_due

      get admin_financial_aid_request_path(financial_aid)

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include("Financial Aid Request ##{financial_aid.id}")
      expect(body).to include('Balance Due')
      expect(body).to include(ApplicationController.helpers.humanized_money_with_symbol(expected.to_f / 100))
      expect(body).to include(admin_application_path(enrollment))
      expect(body).to include('$52,000.00')
      expect(body).to include('Needs help with tuition')
      expect(body).to include('Add a comment')
      expect(body).to include('>Delete<')
    end

    it 'links the supporting document when attached' do
      with_taxform = create(:financial_aid, :pending, :with_taxform, enrollment: enrollment)

      get admin_financial_aid_request_path(with_taxform)

      expect(response.body).to include('taxform.pdf')
    end
  end

  describe 'GET /admin/financial_aid_requests/new' do
    it 'shows the applicant select and the status options' do
      get new_admin_financial_aid_request_path

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('name="financial_aid[enrollment_id]"')
      expect(body).to include("Zimmerman, Ada - #{user.email}")
      expect(body).to include('<option value="awarded">awarded</option>')
      expect(body).to include('Supporting Document (Admin Use Only)')
      expect(body).to include('enctype="multipart/form-data"')
    end

    it 'renders the plain form when ?enrollment_id= does not exist' do
      get new_admin_financial_aid_request_path(enrollment_id: 999_999)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<option value="">Select an applicant</option>')
    end

    it 'prefills the applicant from ?enrollment_id= and hides the select' do
      get new_admin_financial_aid_request_path(enrollment_id: enrollment.id)

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include(%(type="hidden" value="#{enrollment.id}" name="financial_aid[enrollment_id]"))
      expect(body).not_to include('<option value="">Select an applicant</option>')
      expect(body).to include('Back to application')
    end
  end

  describe 'POST /admin/financial_aid_requests' do
    it 'creates a pending request' do
      expect do
        post admin_financial_aid_requests_path, params: { financial_aid: { enrollment_id: enrollment.id, note: 'Second request',
                                                                            adjusted_gross_income: 40_000, status: 'pending' } }
      end.to change(FinancialAid, :count).by(1)

      created = FinancialAid.order(:id).last
      expect(response).to redirect_to(admin_financial_aid_request_path(created))
      expect(created.enrollment).to eq(enrollment)
      expect(created.amount_cents).to eq(0)
      follow_redirect!
      expect(response.body).to include('Financial aid request was successfully created.')
    end

    it 'awards aid, emailing the applicant, and stores the amount through money-rails' do
      expect do
        post admin_financial_aid_requests_path, params: { financial_aid: { enrollment_id: enrollment.id, note: 'Awarded',
                                                                            adjusted_gross_income: 40_000, status: 'awarded',
                                                                            amount: '250.75', source: 'Scholarship',
                                                                            payments_deadline: '2030-06-01' } }
      end.to change { ActionMailer::Base.deliveries.size }.by(1)

      created = FinancialAid.order(:id).last
      expect(created.amount_cents).to eq(25_075)
      expect(created.status).to eq('awarded')
      expect(created.payments_deadline).to eq(Date.new(2030, 6, 1))
    end

    it 'refuses a negative award on create' do
      post admin_financial_aid_requests_path, params: { financial_aid: { enrollment_id: enrollment.id, note: 'neg',
                                                                          adjusted_gross_income: 40_000, status: 'awarded',
                                                                          amount: '-250', source: 'Scholarship',
                                                                          payments_deadline: '2030-06-01' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('must be greater than or equal to 0')
      expect(FinancialAid.count).to eq(1)
    end

    it 're-renders the form with the model validation errors' do
      post admin_financial_aid_requests_path, params: { financial_aid: { enrollment_id: enrollment.id, note: 'x',
                                                                          adjusted_gross_income: 40_000, status: 'awarded',
                                                                          amount: '100', source: '' } }

      expect(response).to have_http_status(:unprocessable_content)
      body = CGI.unescapeHTML(response.body)
      expect(body).to include('Source is required when status is awarded and an amount is assigned')
      expect(body).to include('Payments deadline you need to set a date')
      expect(FinancialAid.count).to eq(1)
    end
  end

  describe 'GET /admin/financial_aid_requests/:id/edit' do
    it 'renders the multipart form with the persisted status selected' do
      financial_aid.update_columns(status: 'legacy-status')

      get edit_admin_financial_aid_request_path(financial_aid)

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('enctype="multipart/form-data"')
      expect(body).to include('<option selected="selected" value="legacy-status">legacy-status</option>')
      expect(body).to include('value="125.50"')
      expect(body).not_to include('name="financial_aid[enrollment_id]"')
      expect(body).to include('The application is fixed once the request is recorded.')
      expect(body).to include('Zimmerman, Ada')
    end
  end

  describe 'PATCH /admin/financial_aid_requests/:id' do
    it 'updates the request and uploads a supporting document' do
      patch admin_financial_aid_request_path(financial_aid),
            params: { financial_aid: { note: 'Updated note', adjusted_gross_income: 61_000,
                                       taxform: fixture_file_upload('spec/files/test.pdf', 'application/pdf') } }

      expect(response).to redirect_to(admin_financial_aid_request_path(financial_aid))
      financial_aid.reload
      expect(financial_aid.note).to eq('Updated note')
      expect(financial_aid.adjusted_gross_income).to eq(61_000)
      expect(financial_aid.taxform).to be_attached
    end

    it 'never moves the request to another application' do
      other = create(:enrollment, :accepted, user: create(:user, :with_applicant_detail))

      patch admin_financial_aid_request_path(financial_aid),
            params: { financial_aid: { note: 'moved?', enrollment_id: other.id } }

      expect(response).to redirect_to(admin_financial_aid_request_path(financial_aid))
      financial_aid.reload
      expect(financial_aid.note).to eq('moved?')
      expect(financial_aid.enrollment).to eq(enrollment)
    end

    it 'rejects negative and malformed amounts without saving them' do
      ['-50', 'abc', 'Infinity', '1e3', '12.345'].each do |bad|
        patch admin_financial_aid_request_path(financial_aid), params: { financial_aid: { amount: bad } }

        expect(response).to have_http_status(:unprocessable_content), "#{bad.inspect} was accepted"
        expect(financial_aid.reload.amount_cents).to eq(12_550)
      end
    end

    it 'rejects the request and emails the applicant' do
      expect do
        patch admin_financial_aid_request_path(financial_aid),
              params: { financial_aid: { status: 'rejected', payments_deadline: '2030-06-01' } }
      end.to change { ActionMailer::Base.deliveries.size }.by(1)

      expect(financial_aid.reload.status).to eq('rejected')
    end

    it 're-renders the form with errors when invalid' do
      patch admin_financial_aid_request_path(financial_aid), params: { financial_aid: { note: '' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(CGI.unescapeHTML(response.body)).to include("Note can't be blank")
    end
  end

  describe 'DELETE /admin/financial_aid_requests/:id' do
    it 'destroys the request' do
      expect { delete admin_financial_aid_request_path(financial_aid) }.to change(FinancialAid, :count).by(-1)
      expect(response).to redirect_to(admin_financial_aid_requests_path)
    end
  end

  describe 'POST /admin/financial_aid_requests/batch' do
    it 'destroys the selected requests' do
      other = create(:financial_aid, :pending, enrollment: enrollment)

      expect do
        post batch_admin_financial_aid_requests_path, params: { batch_action: 'destroy', ids: [financial_aid.id, other.id] }
      end.to change(FinancialAid, :count).by(-2)

      expect(response).to redirect_to(admin_financial_aid_requests_path)
      expect(flash[:notice]).to include('Deleted 2')
    end

    it 'rejects unknown batch actions' do
      post batch_admin_financial_aid_requests_path, params: { batch_action: 'nuke', ids: [financial_aid.id] }

      expect(response).to redirect_to(admin_financial_aid_requests_path)
      expect(flash[:alert]).to include('Unknown batch action')
      expect(FinancialAid.exists?(financial_aid.id)).to be(true)
    end
  end

  describe 'public routes' do
    before do
      sign_out admin
      sign_in user
    end

    it 'no longer has the admin-only index and destroy' do
      get '/financial_aids'
      expect(response).to have_http_status(:not_found)

      delete "/financial_aids/#{financial_aid.id}"
      expect(response).to have_http_status(:not_found)

      delete "/enrollments/#{enrollment.id}/financial_aids/#{financial_aid.id}"
      expect(response).to have_http_status(:not_found)

      expect(FinancialAid.exists?(financial_aid.id)).to be(true)
    end

    it 'keeps the applicant-facing request form' do
      get new_enrollment_financial_aid_path(enrollment)

      expect(response).to have_http_status(:ok)
    end
  end
end
