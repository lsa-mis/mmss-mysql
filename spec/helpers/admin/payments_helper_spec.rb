# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::PaymentsHelper, type: :helper do
  describe "#admin_payment_applicant_label" do
    it "uses the applicant full name when present" do
      user = build_stubbed(:user, email: "camper@example.com")
      detail = build_stubbed(:applicant_detail, user: user, firstname: "Ada", lastname: "Lovelace")
      enrollment = build_stubbed(:enrollment, user: user, campyear: 2026)
      allow(enrollment).to receive(:applicant_detail).and_return(detail)

      expect(helper.admin_payment_applicant_label(enrollment))
        .to eq("Lovelace, Ada · 2026 application")
    end

    it "falls back to the account email when applicant details are missing" do
      user = build_stubbed(:user, email: "orphan@example.com")
      enrollment = build_stubbed(:enrollment, user: user, campyear: 2025)
      allow(enrollment).to receive(:applicant_detail).and_return(nil)

      expect(helper.admin_payment_applicant_label(enrollment))
        .to eq("orphan@example.com · 2025 application")
    end
  end

  describe "#admin_payment_status_badge" do
    it "returns the empty placeholder for a blank status" do
      expect(helper.admin_payment_status_badge(nil)).to include(Admin::FormatHelper::EMPTY)
      expect(helper.admin_payment_status_badge("")).to include(Admin::FormatHelper::EMPTY)
    end

    it "marks Nelnet status 1 as the successful green badge" do
      html = helper.admin_payment_status_badge("1")

      expect(html).to include("admin-badge-green")
      expect(html).to include("1 · #{helper.transaction_status_message("1")}")
    end

    it "marks non-success Nelnet statuses as red badges" do
      html = helper.admin_payment_status_badge("2")

      expect(html).to include("admin-badge-red")
      expect(html).to include("2 · #{helper.transaction_status_message("2")}")
    end
  end

  describe "#admin_payment_user_options" do
    it "appends the payment payer when they are not in the current-camp list" do
      user = create(:user, email: "legacy-payer@example.com")
      payment = build_stubbed(:payment, user: user, user_id: user.id)

      allow(Admin::EnrollmentOptions).to receive(:current_camp_users)
        .and_return([["Current Camper - current@example.com", 999]])

      options = helper.admin_payment_user_options(payment)

      expect(options).to include(["Current Camper - current@example.com", 999])
      expect(options).to include(["legacy-payer@example.com", user.id])
    end

    it "does not duplicate a payer already present in the current-camp list" do
      user = create(:user, email: "current-payer@example.com")
      payment = build_stubbed(:payment, user: user, user_id: user.id)

      allow(Admin::EnrollmentOptions).to receive(:current_camp_users)
        .and_return([["Current Camper - current-payer@example.com", user.id]])

      options = helper.admin_payment_user_options(payment)

      expect(options).to eq([["Current Camper - current-payer@example.com", user.id]])
    end
  end
end
