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
      %w[user[email] user[password] user[password_confirmation]].each do |name|
        # Attribute order is not guaranteed; require both markers on the same <input>.
        expect(body).to match(
          /<input\b(?=[^>]*\bname="#{Regexp.escape(name)}")(?=[^>]*\brequired\b)(?=[^>]*\baria-required="true")[^>]*>/
        )
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
      # Email must not steal focus from the alert after a failed Turbo sign-in.
      expect(body).not_to match(/<input\b(?=[^>]*\bname="user\[email\]")(?=[^>]*\bautofocus\b)[^>]*>/)
    end
  end
end
