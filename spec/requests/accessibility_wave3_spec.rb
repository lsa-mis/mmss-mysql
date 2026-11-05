# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Wave 3 SiteImprove accessibility (forms & status messages)", type: :request do
  describe "GET /users/sign_up (LRA-1458)" do
    it "identifies required fields visibly and programmatically before submit" do
      get new_user_registration_path

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include("Required fields are marked with an asterisk")
      expect(body).to include('data-controller="required-stars"')
      expect(body).to include('aria-required="true"')
      %w[user[email] user[password] user[password_confirmation]].each do |name|
        expect(body).to match(/name="#{Regexp.escape(name)}"[^>]*\brequired\b/)
      end
    end
  end

  describe "POST /users/sign_in with bad credentials (LRA-1511)" do
    it "announces the sign-in error with role=alert, focus target, and error title" do
      post user_session_path, params: {user: {email: "nobody@example.com", password: "wrong-password"}}

      expect(response).to have_http_status(:unprocessable_content)
      body = response.body
      expect(body).to include('id="alert"')
      expect(body).to include('role="alert"')
      expect(body).to include('data-controller="flash-focus"')
      expect(body).to include('tabindex="-1"')
      expect(body).to include("Error — MMSS Application")
    end
  end
end
