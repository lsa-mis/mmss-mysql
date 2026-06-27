# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin applications", type: :request do
  describe "GET /admin/applications/:id/edit" do
    let(:admin) { create(:admin) }
    let(:user) { create(:user, :with_applicant_detail) }
    let(:enrollment) { create(:enrollment, user: user, high_school_country: "US") }

    before do
      sign_in admin
    end

    it "renders the edit form with a country select" do
      get edit_admin_application_path(enrollment)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('name="enrollment[high_school_country]"')
      expect(response.body).to include('<option selected="selected" value="US">United States of America</option>')
    end
  end
end
