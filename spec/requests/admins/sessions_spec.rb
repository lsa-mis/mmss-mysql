# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin sign in', type: :request do
  let(:admin) { create(:admin, password: 'AdminPassword123!', password_confirmation: 'AdminPassword123!') }

  it 'renders the login page in the admin auth layout' do
    get new_admin_session_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Admin sign in')
    expect(response.body).to include('/assets/admin-')
    expect(response.body).to include('name="admin[email]"')
    expect(response.body).to include('Forgot your password?')
  end

  it 'signs an admin in and lands on the dashboard' do
    post admin_session_path, params: { admin: { email: admin.email, password: 'AdminPassword123!' } }

    expect(response).to redirect_to(admin_root_path)
    follow_redirect!
    expect(response.body).to include('Dashboard')
  end

  it 'shows an error for bad credentials' do
    post admin_session_path, params: { admin: { email: admin.email, password: 'wrong' } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include('Invalid email or password')
  end

  it 'signs out with DELETE /admin/logout' do
    sign_in admin

    delete destroy_admin_session_path

    expect(response).to redirect_to(root_path)
    get admin_root_path
    expect(response).to redirect_to(new_admin_session_path)
  end

  it 'renders the password reset and unlock pages' do
    get new_admin_password_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Forgot your password?')

    get new_admin_unlock_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Resend unlock instructions')
  end
end
