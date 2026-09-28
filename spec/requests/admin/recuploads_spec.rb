# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin recuploads', type: :request do
  let(:admin) { create(:admin) }
  let(:user) { create(:user, :with_applicant_detail) }
  let(:enrollment) { create(:enrollment, user: user) }
  let(:recommendation) { create(:recommendation, enrollment: enrollment, firstname: 'Grace', lastname: 'Hopper') }
  let!(:recupload) { create(:recupload, recommendation: recommendation, authorname: 'Dr. Grace Hopper', studentname: 'Ada Zimmerman') }

  before do
    user.applicant_detail.update!(lastname: 'Zimmerman', firstname: 'Ada')
    sign_in admin
  end

  describe 'GET /admin/recuploads' do
    it 'lists uploads with the recommendation link, applicant, author, letter and file' do
      get admin_recuploads_path

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include(admin_recommendation_path(recommendation))
      expect(body).to include('Zimmerman, Ada')
      expect(body).to include(admin_application_path(enrollment))
      expect(body).to include('Dr. Grace Hopper')
      expect(body).to include('This is a test recommendation letter.')
      expect(body).to include('With selected:')
      expect(body).to include('Download CSV')
      expect(body).to include(edit_admin_recupload_path(recupload))
    end

    it 'links the attached file' do
      with_file = create(:recupload, :with_file, recommendation: create(:recommendation, enrollment: create(:enrollment, user: create(:user, :with_applicant_detail))))

      get admin_recuploads_path

      expect(response.body).to include('recommendation_letter.pdf')
      expect(response.body).to include(edit_admin_recupload_path(with_file))
    end

    it 'filters by student name, author and upload date' do
      other = create(:recupload, recommendation: create(:recommendation, enrollment: create(:enrollment, user: create(:user, :with_applicant_detail))),
                                 authorname: 'Prof. Turing', studentname: 'Bob Builder')

      get admin_recuploads_path, params: { q: { studentname: 'Zimmer' } }
      expect(response.body).to include(edit_admin_recupload_path(recupload))
      expect(response.body).not_to include(edit_admin_recupload_path(other))

      get admin_recuploads_path, params: { q: { authorname: 'turing' } }
      expect(response.body).to include(edit_admin_recupload_path(other))
      expect(response.body).not_to include(edit_admin_recupload_path(recupload))

      get admin_recuploads_path, params: { q: { created_at_from: Date.current.to_s, created_at_to: Date.current.to_s } }
      expect(response.body).to include(edit_admin_recupload_path(recupload))
      expect(response.body).to include(edit_admin_recupload_path(other))

      get admin_recuploads_path, params: { q: { created_at_to: '2000-01-01' } }
      expect(response.body).not_to include(edit_admin_recupload_path(recupload))
    end

    it 'sorts by applicant through the joins' do
      %w[recommendation_id applicant authorname nope].each do |key|
        get admin_recuploads_path, params: { sort: key, direction: 'desc' }
        expect(response).to have_http_status(:ok)
      end
    end

    it 'never turns URL options smuggled into the query string into off-site links' do
      get admin_recuploads_path, params: { host: 'evil.example', protocol: 'https', port: 8443, script_name: '/x',
                                           only_path: 'false', sort: 'authorname', q: { authorname: 'Hop' } }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('evil.example')
      expect(response.body).not_to include('https://')
      expect(response.body).to include('href="/admin/recuploads?')
      expect(response.body).to include('q%5Bauthorname%5D=Hop')
    end

    it 'paginates 30 rows per page' do
      32.times { create(:recupload, recommendation: create(:recommendation, enrollment: create(:enrollment, user: create(:user, :with_applicant_detail)))) }

      get admin_recuploads_path
      expect(response.body.scan('<tr id="recupload_').size).to eq(30)
      expect(response.body).to include('rel="next"')

      get admin_recuploads_path, params: { page: 2 }
      expect(response.body).to include('Showing <span class="font-medium">31</span>–<span class="font-medium">33</span>')
    end

    it 'exports CSV' do
      get admin_recuploads_path(format: :csv)

      expect(response.media_type).to eq('text/csv')
      csv = CSV.parse(response.body)
      expect(csv.first).to eq(['Id', 'Recommendation', 'Applicant', 'Applicant email', 'Authorname', 'Studentname', 'Letter', 'Attached file',
                               'Created at', 'Updated at'])
      expect(csv.second[1..5]).to eq([recommendation.id.to_s, 'Zimmerman, Ada', user.email, 'Dr. Grace Hopper', 'Ada Zimmerman'])
    end
  end

  describe 'GET /admin/recuploads/:id' do
    it 'renders the attributes and comments' do
      get admin_recupload_path(recupload)

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include("Recommendation ##{recommendation.id} (Grace Hopper)")
      expect(body).to include(admin_application_path(enrollment))
      expect(body).to include('This is a test recommendation letter.')
      expect(body).to include('resource_type" value="Recupload"')
    end

    it 'accepts admin comments' do
      post admin_comments_path, params: { resource_type: 'Recupload', resource_id: recupload.id, admin_comment: { body: 'Letter verified' } },
                                headers: { 'HTTP_REFERER' => admin_recupload_path(recupload) }

      expect(response).to redirect_to(admin_recupload_path(recupload))
      expect(recupload.admin_comments.pluck(:body)).to eq(['Letter verified'])
    end
  end

  describe 'new/create' do
    it 'renders a multipart form with the applicant-name recommendation select' do
      get new_admin_recupload_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('enctype="multipart/form-data"')
      expect(response.body).to include('Applicant Name')
      expect(response.body).to include("Zimmerman, Ada - #{user.email} (recommender: Grace Hopper)")
      expect(response.body).to include('name="recupload[recletter]"')
    end

    it 'creates an upload with a file and marks the application complete when no fee is required' do
      other_enrollment = create(:enrollment, user: create(:user, :with_applicant_detail))
      other_enrollment.update_columns(application_fee_required: false)
      other_recommendation = create(:recommendation, enrollment: other_enrollment)

      expect do
        post admin_recuploads_path, params: { recupload: { recommendation_id: other_recommendation.id, authorname: 'Prof. X', studentname: 'Y',
                                                           recletter: Rack::Test::UploadedFile.new(Rails.root.join('spec/files/test.pdf'), 'application/pdf') } }
      end.to change(Recupload, :count).by(1)

      created = Recupload.last
      expect(created.recletter).to be_attached
      expect(response).to redirect_to(admin_recupload_path(created))
      expect(other_enrollment.reload.application_status).to eq('application complete')
    end

    it 're-renders with errors when neither letter nor file is given' do
      post admin_recuploads_path, params: { recupload: { recommendation_id: recommendation.id, authorname: 'Prof. X', studentname: 'Y', letter: '' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('must be attached or letter text must be provided')
    end
  end

  describe 'edit/update' do
    it 'renders the edit form with the current file link' do
      recupload.recletter.attach(io: File.open(Rails.root.join('spec/files/test.pdf')), filename: 'letter.pdf', content_type: 'application/pdf')

      get edit_admin_recupload_path(recupload)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('enctype="multipart/form-data"')
      expect(response.body).to include('letter.pdf')
    end

    it 'updates the upload' do
      patch admin_recupload_path(recupload), params: { recupload: { authorname: 'Rear Admiral Hopper' } }

      expect(response).to redirect_to(admin_recupload_path(recupload))
      expect(recupload.reload.authorname).to eq('Rear Admiral Hopper')
    end
  end

  describe 'destroy and batch' do
    it 'destroys the upload' do
      expect { delete admin_recupload_path(recupload) }.to change(Recupload, :count).by(-1)
      expect(response).to redirect_to(admin_recuploads_path)
    end

    it 'destroys the selected uploads' do
      expect { post batch_admin_recuploads_path, params: { batch_action: 'destroy', ids: [recupload.id] } }
        .to change(Recupload, :count).by(-1)
    end
  end

  describe 'public routes' do
    it 'keeps the recommender upload flow and drops the admin-only actions' do
      sign_out admin

      get new_recupload_path, params: { hash: "x_nGklDoc2egIkzFxr0U#{create(:recommendation, enrollment: create(:enrollment, user: create(:user, :with_applicant_detail))).id}" }
      expect(response).to have_http_status(:ok)

      get '/recuploads'
      expect(response).to have_http_status(:not_found)
      get "/recuploads/#{recupload.id}"
      expect(response).to have_http_status(:not_found)
      get "/recuploads/#{recupload.id}/edit"
      expect(response).to have_http_status(:not_found)
      expect { delete "/recuploads/#{recupload.id}" }.not_to change(Recupload, :count)
      expect(response).to have_http_status(:not_found)
    end
  end

  it 'requires an admin' do
    sign_out admin
    get admin_recuploads_path
    expect(response).to redirect_to(new_admin_session_path)
  end
end
