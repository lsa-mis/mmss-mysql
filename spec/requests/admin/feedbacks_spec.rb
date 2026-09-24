# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin feedbacks', type: :request do
  let(:admin) { create(:admin) }
  let(:user) { create(:user, email: 'reporter@example.com') }
  let!(:feedback) { create(:feedback, :page_error, user: user, message: 'The submit button does nothing') }

  before { sign_in admin }

  describe 'GET /admin/feedbacks' do
    it 'lists feedback with filters, actions, batch actions and CSV link' do
      get admin_feedbacks_path

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('The submit button does nothing')
      expect(body).to include('Error on Page')
      expect(body).to include('reporter@example.com')
      expect(body).to include(admin_user_path(user))
      expect(body).to include('Filters')
      %w[q_user_id q_genre q_message q_id q_created_at_from q_updated_at_from].each do |field|
        expect(body).to include(field)
      end
      expect(body).to include('With selected:')
      expect(body).to include('Download CSV')
      expect(body).to include(edit_admin_feedback_path(feedback))
    end

    it 'filters by user, genre, message, id and created date range' do
      other = create(:feedback, :suggestion, user: create(:user), message: 'Add dark mode', created_at: Time.zone.local(2020, 1, 15, 12))

      get admin_feedbacks_path, params: { q: { user_id: user.id } }
      expect(response.body).to include('The submit button does nothing')
      expect(response.body).not_to include('Add dark mode')

      get admin_feedbacks_path, params: { q: { genre: 'suggestion' } }
      expect(response.body).to include('Add dark mode')
      expect(response.body).not_to include('The submit button does nothing')

      get admin_feedbacks_path, params: { q: { message: 'dark' } }
      expect(response.body).to include('Add dark mode')
      expect(response.body).not_to include('The submit button does nothing')

      get admin_feedbacks_path, params: { q: { id: other.id } }
      expect(response.body).to include('Add dark mode')
      expect(response.body).not_to include('The submit button does nothing')

      get admin_feedbacks_path, params: { q: { created_at_from: '2020-01-01', created_at_to: '2020-01-31' } }
      expect(response.body).to include('Add dark mode')
      expect(response.body).not_to include('The submit button does nothing')
      expect(response.body).to include('2 active filters')
    end

    it 'sorts by an allowed column (including the joined user email) and ignores unknown ones' do
      create(:feedback, user: create(:user, email: 'aaron@example.com'), message: 'First alphabetically')

      get admin_feedbacks_path, params: { sort: 'user', direction: 'asc' }
      expect(response).to have_http_status(:ok)
      expect(response.body.index('aaron@example.com')).to be < response.body.index('reporter@example.com')

      get admin_feedbacks_path, params: { sort: 'genre', direction: 'desc' }
      expect(response).to have_http_status(:ok)

      get admin_feedbacks_path, params: { sort: 'drop table' }
      expect(response).to have_http_status(:ok)
    end

    it 'never turns URL options smuggled into the query string into off-site links' do
      get admin_feedbacks_path, params: { host: 'evil.example', protocol: 'https', port: 8443, script_name: '/x', only_path: 'false',
                              sort: 'genre', direction: 'asc', q: { message: 'submit' } }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('evil.example')
      expect(response.body).not_to include('https://')
      expect(response.body).to include('href="/admin/feedbacks?')
      expect(response.body).to include('direction=desc')
      expect(response.body).to include('q%5Bmessage%5D=submit')
    end

    it 'exports CSV' do
      get admin_feedbacks_path(format: :csv)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/csv')
      expect(response.headers['Content-Disposition']).to include('MMSS-feedbacks-')
      csv = CSV.parse(response.body)
      expect(csv.first).to eq(['Id', 'Genre', 'Message', 'User', 'Created at', 'Updated at'])
      expect(csv.second[1]).to eq('page_error')
      expect(csv.second[2]).to eq('The submit button does nothing')
      expect(csv.second[3]).to eq('reporter@example.com')
    end
  end

  describe 'GET /admin/feedbacks/:id' do
    it 'renders the feedback' do
      get admin_feedback_path(feedback)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Feedback ##{feedback.id}")
      expect(response.body).to include('Error on Page')
      expect(response.body).to include('The submit button does nothing')
      expect(response.body).to include(admin_user_path(user))
    end
  end

  it 'has no new/create (feedback is written by applicants on the public site)' do
    expect(Rails.application.routes.url_helpers).not_to respond_to(:new_admin_feedback_path)
    expect { post admin_feedbacks_path, params: { feedback: { genre: 'suggestion', message: 'x' } } }.not_to change(Feedback, :count)
    expect(response).to have_http_status(:not_found)
    get admin_feedbacks_path
    expect(response.body).not_to include('New Feedback')
  end

  describe 'GET /admin/feedbacks/:id/edit' do
    it 'renders the form with genre and message inputs only' do
      get edit_admin_feedback_path(feedback)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('name="feedback[genre]"')
      expect(response.body).to include('name="feedback[message]"')
      expect(response.body).not_to include('name="feedback[user_id]"')
      expect(response.body).to include('Layout Issue')
      expect(response.body).to include("Submitted by #{user.email}")
    end
  end

  describe 'PATCH /admin/feedbacks/:id' do
    it 'updates the feedback and ignores user_id' do
      patch admin_feedback_path(feedback), params: { feedback: { genre: 'layout_issue', message: 'Button overlaps footer', user_id: create(:user).id } }

      expect(response).to redirect_to(admin_feedback_path(feedback))
      feedback.reload
      expect(feedback.genre).to eq('layout_issue')
      expect(feedback.message).to eq('Button overlaps footer')
      expect(feedback.user).to eq(user)
    end

    it 're-renders with errors when blank' do
      patch admin_feedback_path(feedback), params: { feedback: { genre: '', message: '' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(CGI.unescapeHTML(response.body)).to include("Genre can't be blank")
      expect(CGI.unescapeHTML(response.body)).to include("Message can't be blank")
    end

    it 're-renders with errors when the message is too long' do
      patch admin_feedback_path(feedback), params: { feedback: { message: 'x' * (Feedback::MESSAGE_MAX_LENGTH + 1) } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('is too long')
    end
  end

  describe 'DELETE /admin/feedbacks/:id' do
    it 'destroys the feedback' do
      expect { delete admin_feedback_path(feedback) }.to change(Feedback, :count).by(-1)
      expect(response).to redirect_to(admin_feedbacks_path)
    end
  end

  describe 'POST /admin/feedbacks/batch' do
    it 'destroys the selected feedback' do
      other = create(:feedback, user: user)

      expect do
        post batch_admin_feedbacks_path, params: { batch_action: 'destroy', ids: [feedback.id, other.id] }
      end.to change(Feedback, :count).by(-2)

      expect(response).to redirect_to(admin_feedbacks_path)
      expect(flash[:notice]).to include('Deleted 2')
    end
  end

  it 'requires an admin' do
    sign_out admin

    get admin_feedbacks_path

    expect(response).to redirect_to(new_admin_session_path)
  end
end
