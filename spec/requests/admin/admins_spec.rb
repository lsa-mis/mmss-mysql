# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin admins', type: :request do
  let(:admin) { create(:admin, email: 'me@example.com') }
  let!(:other) { create(:admin, :with_sign_ins, email: 'colleague@example.com') }

  before { sign_in admin }

  describe 'GET /admin/admins' do
    it 'lists admin accounts with actions, batch actions and CSV link (no filters)' do
      get admin_admins_path

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('colleague@example.com')
      expect(body).to include('me@example.com')
      expect(body).to include('>you<')
      expect(body).to include('With selected:')
      expect(body).to include('Download CSV')
      expect(body).to include(edit_admin_admin_path(other))
      expect(body).to include(new_admin_admin_path)
      expect(body).not_to include('Filters')
    end

    it 'sorts by an allowed column and ignores unknown ones' do
      get admin_admins_path, params: { sort: 'email', direction: 'asc' }
      expect(response).to have_http_status(:ok)
      expect(response.body.index(%(id="admin_#{other.id}"))).to be < response.body.index(%(id="admin_#{admin.id}"))

      get admin_admins_path, params: { sort: 'encrypted_password' }
      expect(response).to have_http_status(:ok)
    end

    it 'flags locked accounts' do
      create(:admin, email: 'locked@example.com', locked_at: 5.minutes.ago, failed_attempts: 20)

      get admin_admins_path

      expect(response.body).to include('locked')
    end

    it 'exports CSV without any credential columns' do
      get admin_admins_path(format: :csv)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/csv')
      expect(response.headers['Content-Disposition']).to include('MMSS-admins-')
      csv = CSV.parse(response.body)
      expect(csv.first).to eq(['Id', 'Email', 'Current sign in at', 'Last sign in at', 'Sign in count', 'Locked at', 'Created at', 'Updated at'])
      expect(csv.map { |row| row[1] }).to include('colleague@example.com', 'me@example.com')
      expect(response.body).not_to include('encrypted_password')
    end
  end

  describe 'GET /admin/admins/:id' do
    it 'renders the account and sign-in activity' do
      get admin_admin_path(other)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Admin ##{other.id}")
      expect(response.body).to include('Sign-in activity')
      expect(response.body).to include(other.current_sign_in_ip)
      expect(response.body).to include('active')
      expect(response.body).not_to include('Unlock account')
    end

    it 'offers to unlock a locked account and hides delete for the signed-in admin' do
      locked = create(:admin, locked_at: 5.minutes.ago, failed_attempts: 20)

      get admin_admin_path(locked)
      expect(response.body).to include('Unlock account')

      get admin_admin_path(admin)
      expect(response.body).not_to include('Delete this admin account')
    end
  end

  describe 'GET /admin/admins/new' do
    it 'requires the password fields on create' do
      get new_admin_admin_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('name="admin[password]"')
      expect(response.body).to match(/<input[^>]*required[^>]*name="admin\[password\]"/)
      expect(response.body).to include('At least 6 characters')
    end
  end

  describe 'POST /admin/admins' do
    it 'creates an admin account' do
      expect do
        post admin_admins_path, params: { admin: { email: 'new@example.com', password: 'passwordpassword', password_confirmation: 'passwordpassword' } }
      end.to change(Admin, :count).by(1)

      expect(response).to redirect_to(admin_admin_path(Admin.find_by(email: 'new@example.com')))
    end

    it 're-renders with errors when the password is missing' do
      post admin_admins_path, params: { admin: { email: 'new@example.com', password: '', password_confirmation: '' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(CGI.unescapeHTML(response.body)).to include("Password can't be blank")
    end
  end

  describe 'GET /admin/admins/:id/edit' do
    it 'renders the form with optional, never pre-filled password fields' do
      get edit_admin_admin_path(other)

      expect(response).to have_http_status(:ok)
      expect(CGI.unescapeHTML(response.body)).to include("Leave blank if you don't want to change the password")
      password_input = response.body[/<input[^>]*name="admin\[password\]"[^>]*>/]
      expect(password_input).not_to include('required')
      expect(password_input).not_to include('value=')
      expect(response.body).not_to include(other.encrypted_password)
    end
  end

  describe 'PATCH /admin/admins/:id' do
    it 'changes the email without touching the password when the password fields are blank' do
      original_password = other.encrypted_password

      patch admin_admin_path(other), params: { admin: { email: 'renamed@example.com', password: '', password_confirmation: '' } }

      expect(response).to redirect_to(admin_admin_path(other))
      other.reload
      expect(other.email).to eq('renamed@example.com')
      expect(other.encrypted_password).to eq(original_password)
    end

    it 'changes the password when one is given' do
      patch admin_admin_path(other), params: { admin: { email: other.email, password: 'newpassword123', password_confirmation: 'newpassword123' } }

      expect(response).to redirect_to(admin_admin_path(other))
      expect(other.reload.valid_password?('newpassword123')).to be(true)
    end

    it 're-renders with errors when the confirmation does not match' do
      patch admin_admin_path(other), params: { admin: { email: other.email, password: 'newpassword123', password_confirmation: 'different' } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(CGI.unescapeHTML(response.body)).to include("Password confirmation doesn't match")
    end
  end

  describe 'POST /admin/admins/:id/unlock' do
    it 'unlocks a locked account' do
      locked = create(:admin, locked_at: 5.minutes.ago, failed_attempts: 20)

      post unlock_admin_admin_path(locked)

      expect(response).to redirect_to(admin_admin_path(locked))
      expect(locked.reload.access_locked?).to be(false)
      expect(flash[:notice]).to include('unlocked')
    end
  end

  describe 'DELETE /admin/admins/:id' do
    it 'destroys another admin' do
      expect { delete admin_admin_path(other) }.to change(Admin, :count).by(-1)
      expect(response).to redirect_to(admin_admins_path)
    end

    it 'refuses to delete the signed-in admin' do
      expect { delete admin_admin_path(admin) }.not_to change(Admin, :count)
      expect(response).to redirect_to(admin_admin_path(admin))
      expect(flash[:alert]).to include('signed in with')
    end
  end

  describe 'POST /admin/admins/batch' do
    it 'destroys the selected admins but never the signed-in one' do
      third = create(:admin)

      expect do
        post batch_admin_admins_path, params: { batch_action: 'destroy', ids: [other.id, third.id, admin.id] }
      end.to change(Admin, :count).by(-2)

      expect(response).to redirect_to(admin_admins_path)
      expect(flash[:notice]).to include('Deleted 2')
      expect(Admin.exists?(admin.id)).to be(true)
    end
  end

  it 'requires an admin' do
    sign_out admin

    get admin_admins_path

    expect(response).to redirect_to(new_admin_session_path)
  end

  it 'no longer redirects /admin/admins to the legacy admin' do
    get '/admin/admins'

    expect(response).to have_http_status(:ok)
  end
end
