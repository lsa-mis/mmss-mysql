# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::EnrollmentOptions do
  let!(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year) }

  before do
    allow(CampConfiguration).to receive(:active_camp_year).and_return(camp_config.camp_year)
  end

  describe ".label" do
    it "joins applicant full name and email" do
      user = create(:user, :with_applicant_detail, email: "ada@example.com")
      user.applicant_detail.update!(lastname: "Lovelace", firstname: "Ada")
      enrollment = create(:enrollment, user: user, campyear: camp_config.camp_year)

      expect(described_class.label(enrollment)).to eq("Lovelace, Ada - ada@example.com")
    end

    it "falls back to email when the applicant has no detail record" do
      user = create(:user, email: "bare@example.com")
      enrollment = create(:enrollment, user: user, campyear: camp_config.camp_year)

      expect(described_class.label(enrollment)).to eq("bare@example.com")
    end

    it "falls back to the enrollment id when name and email are blank" do
      enrollment = build_stubbed(:enrollment, id: 42)
      allow(enrollment).to receive_messages(applicant_detail: nil, user: nil)

      expect(described_class.label(enrollment)).to eq("Application #42")
    end
  end

  describe ".current_camp" do
    it "returns current-year applications as [label, enrollment_id], sorted case-insensitively" do
      zebra = create(:user, :with_applicant_detail, email: "zebra@example.com")
      zebra.applicant_detail.update!(lastname: "Zebra", firstname: "Zed")
      ada = create(:user, :with_applicant_detail, email: "ada@example.com")
      ada.applicant_detail.update!(lastname: "Anderson", firstname: "Ada")

      zebra_enrollment = create(:enrollment, user: zebra, campyear: camp_config.camp_year)
      ada_enrollment = create(:enrollment, user: ada, campyear: camp_config.camp_year)
      create(:enrollment, user: create(:user), campyear: camp_config.camp_year - 1)

      options = described_class.current_camp

      expect(options.map(&:last)).to eq([ada_enrollment.id, zebra_enrollment.id])
      expect(options.map(&:first)).to eq([
        "Anderson, Ada - ada@example.com",
        "Zebra, Zed - zebra@example.com"
      ])
    end

    it "keeps an older persisted enrollment selectable via include:" do
      current = create(:enrollment, user: create(:user, :with_applicant_detail), campyear: camp_config.camp_year)
      older = create(:enrollment, user: create(:user, :with_applicant_detail), campyear: camp_config.camp_year - 1)

      options = described_class.current_camp(include: older)

      expect(options.map(&:last)).to contain_exactly(current.id, older.id)
    end

    it "does not duplicate an enrollment that is already in the current-year set" do
      enrollment = create(:enrollment, user: create(:user, :with_applicant_detail), campyear: camp_config.camp_year)

      options = described_class.current_camp(include: enrollment)

      expect(options.map(&:last)).to eq([enrollment.id])
    end
  end

  describe ".current_camp_users" do
    it "returns [label, user_id] pairs and keeps a user without a current application selectable" do
      current_user = create(:user, :with_applicant_detail, email: "current@example.com")
      current_user.applicant_detail.update!(lastname: "Current", firstname: "Cam")
      create(:enrollment, user: current_user, campyear: camp_config.camp_year)

      orphan_user = create(:user, email: "orphan@example.com")
      orphan_enrollment = build_stubbed(:enrollment, id: 99, user: orphan_user, campyear: camp_config.camp_year - 1)
      allow(orphan_enrollment).to receive(:applicant_detail).and_return(nil)

      options = described_class.current_camp_users(include: orphan_enrollment)

      expect(options).to include(["Current, Cam - current@example.com", current_user.id])
      expect(options).to include(["orphan@example.com", orphan_user.id])
    end

    it "deduplicates when include: is an older enrollment for a user who already has a current application" do
      user = create(:user, :with_applicant_detail, email: "dup@example.com")
      user.applicant_detail.update!(lastname: "Dup", firstname: "Dee")
      create(:enrollment, user: user, campyear: camp_config.camp_year)
      older = create(:enrollment, user: user, campyear: camp_config.camp_year - 1)

      options = described_class.current_camp_users(include: older)

      expect(options.count { |_label, id| id == user.id }).to eq(1)
    end
  end
end
