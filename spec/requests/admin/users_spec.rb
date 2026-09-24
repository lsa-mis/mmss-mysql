# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin users', type: :request do
  let(:admin) { create(:admin) }
  let!(:user) { create(:user, :with_sign_ins, :with_applicant_detail, email: 'zoe.applicant@example.com') }
  let!(:other) { create(:user, email: 'adam.other@example.com') }

  before { sign_in admin }

  describe 'GET /admin/users' do
    it 'lists users with the email filter, actions, batch actions and CSV link' do
      get admin_users_path

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('zoe.applicant@example.com')
      expect(body).to include('adam.other@example.com')
      expect(body).to include('Filters')
      expect(body).to include('q_email')
      expect(body).to include('With selected:')
      expect(body).to include('Download CSV')
      expect(body).to include(edit_admin_user_path(user))
      expect(body).to include(new_admin_user_path)
    end

    it 'filters by email (contains)' do
      get admin_users_path, params: { q: { email: 'zoe' } }

      expect(response.body).to include('zoe.applicant@example.com')
      expect(response.body).not_to include('adam.other@example.com')
      expect(response.body).to include('1 active filter')
    end

    it 'sorts by an allowed column and ignores unknown ones' do
      get admin_users_path, params: { sort: 'email', direction: 'asc' }
      expect(response).to have_http_status(:ok)
      expect(response.body.index('adam.other@example.com')).to be < response.body.index('zoe.applicant@example.com')

      get admin_users_path, params: { sort: 'email', direction: 'desc' }
      expect(response.body.index('zoe.applicant@example.com')).to be < response.body.index('adam.other@example.com')

      get admin_users_path, params: { sort: 'encrypted_password' }
      expect(response).to have_http_status(:ok)
    end

    it 'never turns URL options smuggled into the query string into off-site links' do
      get admin_users_path, params: { host: 'evil.example', protocol: 'https', port: 8443, script_name: '/x', only_path: 'false',
                              sort: 'email', direction: 'asc', q: { email: 'zoe' } }

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('evil.example')
      expect(response.body).not_to include('https://')
      expect(response.body).to include('href="/admin/users?')
      expect(response.body).to include('direction=desc')
      expect(response.body).to include('q%5Bemail%5D=zoe')
    end

    it 'paginates with a configurable page size' do
      get admin_users_path, params: { limit: 1 }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Showing')
      expect(response.body).to include('Next ›')
      expect(response.body).to include('page=2')
    end

    it 'exports the filtered list as CSV without credential columns' do
      get admin_users_path(format: :csv), params: { q: { email: 'zoe' } }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/csv')
      expect(response.headers['Content-Disposition']).to include('MMSS-users-')
      csv = CSV.parse(response.body)
      expect(csv.first).to eq(['Id', 'Email', 'Current sign in at', 'Last sign in at', 'Sign in count', 'Created at', 'Updated at'])
      expect(csv.size).to eq(2)
      expect(csv.second[1]).to eq('zoe.applicant@example.com')
      expect(csv.second[4]).to eq(user.sign_in_count.to_s)
    end
  end

  describe 'GET /admin/users/:id' do
    it 'renders the user, applicant detail link, applications panel and sign-in activity' do
      enrollment = create(:enrollment, user: user)

      get admin_user_path(user)

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include("User ##{user.id}")
      expect(body).to include(user.applicant_detail.full_name.titleize)
      expect(body).to include('Applications')
      expect(body).to include(admin_application_path(enrollment))
      expect(body).to include('Sign-in activity')
      expect(body).to include(user.current_sign_in_ip)
    end

    it 'shows an empty state without applicant detail or applications' do
      get admin_user_path(other)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('not started')
      expect(response.body).to include('No applications.')
    end
  end

  describe 'GET /admin/users/new' do
    it 'requires the password fields on create' do
      get new_admin_user_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to match(/<input[^>]*required[^>]*name="user\[password\]"/)
    end
  end

  describe 'POST /admin/users' do
    it 'creates a user' do
      expect do
        post admin_users_path, params: { user: { email: 'new@example.com', password: 'passwordpassword', password_confirmation: 'passwordpassword' } }
      end.to change(User, :count).by(1)

      expect(response).to redirect_to(admin_user_path(User.find_by(email: 'new@example.com')))
    end

    it 're-renders with errors when invalid' do
      post admin_users_path, params: { user: { email: '', password: 'passwordpassword', password_confirmation: 'passwordpassword' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(CGI.unescapeHTML(response.body)).to include("Email can't be blank")
    end
  end

  describe 'GET /admin/users/:id/edit' do
    it 'renders optional, never pre-filled password fields with the hint' do
      get edit_admin_user_path(user)

      expect(response).to have_http_status(:ok)
      expect(CGI.unescapeHTML(response.body)).to include("Leave blank if you don't want to change the password")
      password_input = response.body[/<input[^>]*name="user\[password\]"[^>]*>/]
      expect(password_input).not_to include('required')
      expect(password_input).not_to include('value=')
      expect(response.body).not_to include(user.encrypted_password)
    end
  end

  describe 'PATCH /admin/users/:id' do
    it 'changes the email without requiring a password (blank password params are dropped)' do
      original_password = user.encrypted_password

      patch admin_user_path(user), params: { user: { email: 'renamed@example.com', password: '', password_confirmation: '' } }

      expect(response).to redirect_to(admin_user_path(user))
      user.reload
      expect(user.email).to eq('renamed@example.com')
      expect(user.encrypted_password).to eq(original_password)
      follow_redirect!
      expect(response.body).to include('User was successfully updated.')
    end

    it 'changes the password when one is given' do
      patch admin_user_path(user), params: { user: { email: user.email, password: 'newpassword123', password_confirmation: 'newpassword123' } }

      expect(user.reload.valid_password?('newpassword123')).to be(true)
    end

    it 're-renders with errors when invalid' do
      patch admin_user_path(user), params: { user: { email: 'adam.other@example.com' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('Email has already been taken')
    end
  end

  describe 'DELETE /admin/users/:id' do
    it 'destroys the user' do
      expect { delete admin_user_path(other) }.to change(User, :count).by(-1)
      expect(response).to redirect_to(admin_users_path)
    end

    it 'refuses to delete a user with payment requests or payments and explains why' do
      create(:payment_request, user: other)

      expect { delete admin_user_path(other) }.not_to change(User, :count)
      expect(response).to redirect_to(admin_user_path(other))
      expect(flash[:alert]).to include('User could not be deleted')
      expect(flash[:alert]).to include('payment requests')
      expect(PaymentRequest.where(user: other).count).to eq(1)

      get admin_user_path(other)
      expect(response.body).to include('cannot be deleted')
      expect(response.body).not_to include(%(class="button_to" method="post" action="#{admin_user_path(other)}"))
    end
  end

  describe 'POST /admin/users/batch' do
    it 'destroys the selected users' do
      expect do
        post batch_admin_users_path, params: { batch_action: 'destroy', ids: [user.id, other.id] }
      end.to change(User, :count).by(-2)

      expect(response).to redirect_to(admin_users_path)
      expect(flash[:notice]).to include('Deleted 2')
    end

    it 'skips users with payments or payment requests and names them' do
      create(:payment, user: other)

      expect do
        post batch_admin_users_path, params: { batch_action: 'destroy', ids: [user.id, other.id] }
      end.to change(User, :count).by(-1)

      expect(User.exists?(other.id)).to be(true)
      expect(flash[:notice]).to include('Deleted 1 user.')
      expect(flash[:notice]).to include("Skipped 1 with payments or payment requests: #{other.email}")
    end

    it 'rejects unknown batch actions' do
      post batch_admin_users_path, params: { batch_action: 'nuke', ids: [user.id] }

      expect(response).to redirect_to(admin_users_path)
      expect(flash[:alert]).to include('Unknown batch action')
      expect(User.exists?(user.id)).to be(true)
    end
  end

  it 'requires an admin' do
    sign_out admin

    get admin_users_path

    expect(response).to redirect_to(new_admin_session_path)
  end
end
