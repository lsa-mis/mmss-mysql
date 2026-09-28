# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin recommendations', type: :request do
  let(:admin) { create(:admin) }
  let(:user) { create(:user, :with_applicant_detail) }
  let(:enrollment) { create(:enrollment, user: user) }
  let!(:recommendation) do
    create(:recommendation, enrollment: enrollment, firstname: 'Grace', lastname: 'Hopper', email: 'grace@navy.example',
                            organization: 'US Navy', city: 'Arlington')
  end

  before do
    user.applicant_detail.update!(lastname: 'Zimmerman', firstname: 'Ada')
    sign_in admin
  end

  describe 'GET /admin/recommendations' do
    it 'lists recommendations with applicant links, letter status, batch actions and CSV' do
      get admin_recommendations_path

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('Zimmerman, Ada')
      expect(body).to include(admin_application_path(enrollment))
      expect(body).to include('Hopper')
      expect(body).to include('grace@navy.example')
      expect(body).to include('waiting')
      expect(body).to include('With selected:')
      expect(body).to include('Download CSV')
      expect(body).to include(edit_admin_recommendation_path(recommendation))
    end

    it 'filters by applicant last name, recommender last name, email and organization' do
      other = create(:recommendation, enrollment: create(:enrollment, user: create(:user, :with_applicant_detail)),
                                      lastname: 'Lovelace', email: 'ada@analytical.example', organization: 'Analytical Engines')

      get admin_recommendations_path, params: { q: { applicant_lastname: 'Zim' } }
      expect(response.body).to include(edit_admin_recommendation_path(recommendation))
      expect(response.body).not_to include(edit_admin_recommendation_path(other))

      get admin_recommendations_path, params: { q: { lastname: 'love' } }
      expect(response.body).to include(edit_admin_recommendation_path(other))
      expect(response.body).not_to include(edit_admin_recommendation_path(recommendation))

      get admin_recommendations_path, params: { q: { email: 'analytical' } }
      expect(response.body).to include(edit_admin_recommendation_path(other))
      expect(response.body).not_to include(edit_admin_recommendation_path(recommendation))

      get admin_recommendations_path, params: { q: { organization: 'Navy' } }
      expect(response.body).to include(edit_admin_recommendation_path(recommendation))
      expect(response.body).not_to include(edit_admin_recommendation_path(other))
    end

    it 'sorts by applicant through the join and by columns' do
      get admin_recommendations_path, params: { sort: 'enrollment_id', direction: 'asc' }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('direction=desc')

      get admin_recommendations_path, params: { sort: 'organization' }
      expect(response).to have_http_status(:ok)
    end

    it 'never turns URL options smuggled into the query string into off-site links' do
      get admin_recommendations_path, params: { host: 'evil.example', protocol: 'https', port: 8443, script_name: '/x',
                                                only_path: 'false', sort: 'lastname', q: { lastname: 'Hop' } }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('evil.example')
      expect(response.body).not_to include('https://')
      expect(response.body).to include('href="/admin/recommendations?')
      expect(response.body).to include('q%5Blastname%5D=Hop')
    end

    it 'paginates 30 rows per page' do
      32.times { create(:recommendation, enrollment: create(:enrollment, user: create(:user, :with_applicant_detail))) }

      get admin_recommendations_path
      expect(response.body.scan('<tr id="recommendation_').size).to eq(30)
      expect(response.body).to include('rel="next"')

      get admin_recommendations_path, params: { page: 2 }
      expect(response.body).to include('Showing <span class="font-medium">31</span>–<span class="font-medium">33</span>')
    end

    it 'exports CSV' do
      get admin_recommendations_path(format: :csv)

      expect(response.media_type).to eq('text/csv')
      csv = CSV.parse(response.body)
      expect(csv.first).to eq(['Id', 'Applicant', 'Applicant email', 'Email', 'Lastname', 'Firstname', 'Organization', 'Address1',
                               'Address2', 'City', 'State', 'State non us', 'Postalcode', 'Country', 'Phone number',
                               'Best contact time', 'Letter received', 'Created at', 'Updated at'])
      expect(csv.second[1..6]).to eq(['Zimmerman, Ada', user.email, 'grace@navy.example', 'Hopper', 'Grace', 'US Navy'])
      expect(csv.second[16]).to eq('false')
    end
  end

  describe 'GET /admin/recommendations/:id' do
    it 'renders the attributes, the resend button, the letter panel and comments' do
      get admin_recommendation_path(recommendation)

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('Grace Hopper')
      expect(body).to include(admin_application_path(enrollment))
      expect(body).to include(send_request_email_admin_recommendation_path(recommendation))
      expect(body).to include('Waiting for the recommender to respond.')
      expect(body).to include('Add a comment')
      expect(body).to include('resource_type" value="Recommendation"')
    end

    it 'links the uploaded letter when present' do
      recupload = create(:recupload, recommendation: recommendation)

      get admin_recommendation_path(recommendation)

      expect(response.body).to include(admin_recupload_path(recupload))
      expect(response.body).to include('Dr. Test Author')
    end

    it 'accepts admin comments' do
      post admin_comments_path, params: { resource_type: 'Recommendation', resource_id: recommendation.id, admin_comment: { body: 'Called the recommender' } },
                                headers: { 'HTTP_REFERER' => admin_recommendation_path(recommendation) }

      expect(response).to redirect_to(admin_recommendation_path(recommendation))
      expect(recommendation.admin_comments.pluck(:body)).to eq(['Called the recommender'])
    end
  end

  describe 'POST /admin/recommendations/:id/send_request_email' do
    it 'resends the request email and returns to the admin recommendation page' do
      expect do
        post send_request_email_admin_recommendation_path(recommendation)
      end.to change { ActionMailer::Base.deliveries.size }.by(1)

      expect(ActionMailer::Base.deliveries.last.to).to include(recommendation.email)
      expect(response).to redirect_to(admin_recommendation_path(recommendation))
      expect(flash[:notice]).to include('was sent')
    end

    it 'refuses a signed-in applicant without sending anything' do
      sign_out admin
      sign_in create(:user)

      post send_request_email_admin_recommendation_path(recommendation)

      expect(response).to redirect_to(new_admin_session_path)
      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it 'refuses anonymous visitors' do
      sign_out admin

      post send_request_email_admin_recommendation_path(recommendation)

      expect(response).to redirect_to(new_admin_session_path)
    end

    it 'no longer exposes the public GET route' do
      sign_out admin
      sign_in create(:user)

      get "/send_request_email?recommendation_id=#{recommendation.id}"

      expect(response).to have_http_status(:not_found)
      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it 'performs no mutation on GET' do
      get "/admin/recommendations/#{recommendation.id}/send_request_email"

      expect(response).not_to have_http_status(:ok)
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end

  describe 'new/create' do
    it 'renders the form with the applicant select, US states and countries' do
      get new_admin_recommendation_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Zimmerman, Ada - #{user.email}")
      expect(response.body).to include('name="recommendation[state]"')
      expect(response.body).to include('name="recommendation[country]"')
      expect(response.body).to include('United States')
    end

    it 'creates a recommendation' do
      other = create(:enrollment, user: create(:user, :with_applicant_detail))
      params = { enrollment_id: other.id, email: 'rec@example.com', firstname: 'Alan', lastname: 'Turing', organization: 'Bletchley',
                 state: 'MI', country: 'US' }

      expect { post admin_recommendations_path, params: { recommendation: params } }.to change(Recommendation, :count).by(1)
      created = Recommendation.last
      expect(created.enrollment).to eq(other)
      expect(response).to redirect_to(admin_recommendation_path(created))
    end

    it 're-renders with errors when invalid' do
      post admin_recommendations_path, params: { recommendation: { enrollment_id: enrollment.id, email: 'nope', firstname: '', lastname: '' } }

      expect(response).to have_http_status(:unprocessable_content)
      body = CGI.unescapeHTML(response.body)
      expect(body).to include('Email only allows valid emails')
      expect(body).to include("Firstname can't be blank")
    end
  end

  describe 'edit/update' do
    it 'keeps an older enrollment selectable' do
      old_camp = create(:camp_configuration, camp_year: 2019, active: false)
      enrollment.update_columns(campyear: 2019)
      expect(old_camp).to be_persisted

      get edit_admin_recommendation_path(recommendation)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(<option selected="selected" value="#{enrollment.id}">Zimmerman, Ada - #{user.email}</option>))
    end

    it 'updates the recommendation' do
      patch admin_recommendation_path(recommendation), params: { recommendation: { organization: 'Yale' } }

      expect(response).to redirect_to(admin_recommendation_path(recommendation))
      expect(recommendation.reload.organization).to eq('Yale')
    end
  end

  describe 'destroy and batch' do
    it 'destroys the recommendation' do
      expect { delete admin_recommendation_path(recommendation) }.to change(Recommendation, :count).by(-1)
      expect(response).to redirect_to(admin_recommendations_path)
    end

    it 'destroys the selected recommendations' do
      expect { post batch_admin_recommendations_path, params: { batch_action: 'destroy', ids: [recommendation.id] } }
        .to change(Recommendation, :count).by(-1)
    end
  end

  describe 'public routes' do
    it 'no longer exposes the admin-only index and destroy on the public controller' do
      sign_out admin
      sign_in user

      get '/recommendations'
      expect(response).to have_http_status(:not_found)

      expect { delete "/recommendations/#{recommendation.id}" }.not_to change(Recommendation, :count)
      expect(response).to have_http_status(:not_found)
    end
  end

  it 'requires an admin' do
    sign_out admin
    get admin_recommendations_path
    expect(response).to redirect_to(new_admin_session_path)
  end
end
