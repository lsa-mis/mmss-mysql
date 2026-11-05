# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Wave 4 SiteImprove accessibility (admin tables & filters)", type: :request do
  let(:admin) { create(:admin) }
  let(:user) { create(:user, :with_applicant_detail) }
  let!(:enrollment) { create(:enrollment, :application_complete, user: user) }

  before do
    user.applicant_detail.update!(lastname: "Zimmerman", firstname: "Ada")
    sign_in admin
  end

  describe "GET /admin/applications (LRA-1524, LRA-1523, LRA-1525, LRA-1520, LRA-1522 markup)" do
    it "puts aria-sort on the active sortable th, not the inner link" do
      get admin_applications_path, params: {sort: "applicant", direction: "asc"}

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to match(/<th\b[^>]*\baria-sort="ascending"[^>]*>/i)
      expect(body).to include('data-focus-preserve-id="admin-sort-applicant"')
      # Inactive sortable headers must not advertise a sort direction.
      expect(body.scan(/aria-sort="/).size).to eq(1)
      expect(body).not_to match(/<a\b[^>]*\baria-sort=/i)
    end

    it "sets aria-sort=descending when direction is desc" do
      get admin_applications_path, params: {sort: "updated_at", direction: "desc"}

      expect(response).to have_http_status(:ok)
      expect(response.body).to match(/<th\b[^>]*\baria-sort="descending"[^>]*>/i)
    end

    it "places the Filters panel before the data table in DOM order" do
      get admin_applications_path

      body = response.body
      filter_pos = body.index(">Filters</h2>")
      table_pos = body.index('class="admin-table"')
      expect(filter_pos).to be_present
      expect(table_pos).to be_present
      expect(filter_pos).to be < table_pos
      expect(body).to include("xl:order-last")
      expect(body).to include("xl:order-first")
    end

    it "underlines applicant name links on the index" do
      get admin_applications_path

      expect(response.body).to match(
        /<a\b(?=[^>]*\bhref="#{Regexp.escape(admin_application_path(enrollment))}")(?=[^>]*\bclass="[^"]*\bunderline\b)[^>]*>/
      )
    end

    it "gives Actions Delete a ≥24×24 target via min-h-6 min-w-6" do
      get admin_applications_path

      expect(response.body).to match(/class="[^"]*\bmin-h-6\b[^"]*\bmin-w-6\b[^"]*"[^>]*>\s*Delete\s*</)
    end

    it "wires Turbo focus-preserve hooks on filter and sort controls" do
      get admin_applications_path

      body = response.body
      expect(body).to include('data-controller="session-timeout admin-sidebar focus-preserve"')
      expect(body).to include("turbo:submit-start->focus-preserve#captureSubmit")
      expect(body).to include('data-focus-preserve-id="admin-filter-submit"')
      expect(body).to include('data-focus-preserve-id="admin-filter-clear"')
      expect(body).to include("click->focus-preserve#capture")
    end
  end

  describe "GET /admin/applications/:id (LRA-1525)" do
    it "underlines the applicant name link on the review/details page" do
      get admin_application_path(enrollment)

      expect(response).to have_http_status(:ok)
      detail = user.applicant_detail
      expect(response.body).to match(
        /<a\b(?=[^>]*\bhref="#{Regexp.escape(admin_applicant_detail_path(detail))}")(?=[^>]*\bclass="[^"]*\bunderline\b)[^>]*>/
      )
    end
  end
end
