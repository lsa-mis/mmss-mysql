# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::RecommendationOptions do
  let!(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year) }

  before do
    allow(CampConfiguration).to receive(:active_camp_year).and_return(camp_config.camp_year)
  end

  describe ".label" do
    it "joins the enrollment label with the recommender full name" do
      user = create(:user, :with_applicant_detail, email: "ada@example.com")
      user.applicant_detail.update!(lastname: "Lovelace", firstname: "Ada")
      enrollment = create(:enrollment, user: user, campyear: camp_config.camp_year)
      recommendation = create(:recommendation, enrollment: enrollment, firstname: "Grace", lastname: "Hopper")

      expect(described_class.label(recommendation))
        .to eq("Lovelace, Ada - ada@example.com (recommender: Grace Hopper)")
    end
  end

  describe ".current_camp" do
    it "returns current-year recommendations as [label, id], sorted case-insensitively" do
      zebra = create(:user, :with_applicant_detail, email: "zebra@example.com")
      zebra.applicant_detail.update!(lastname: "Zebra", firstname: "Zed")
      ada = create(:user, :with_applicant_detail, email: "ada@example.com")
      ada.applicant_detail.update!(lastname: "Anderson", firstname: "Ada")

      zebra_enrollment = create(:enrollment, user: zebra, campyear: camp_config.camp_year)
      ada_enrollment = create(:enrollment, user: ada, campyear: camp_config.camp_year)
      older_enrollment = create(:enrollment, user: create(:user), campyear: camp_config.camp_year - 1)

      zebra_rec = create(:recommendation, enrollment: zebra_enrollment, firstname: "Zed", lastname: "Rec")
      ada_rec = create(:recommendation, enrollment: ada_enrollment, firstname: "Ann", lastname: "Rec")
      create(:recommendation, enrollment: older_enrollment, firstname: "Old", lastname: "Rec")

      options = described_class.current_camp

      expect(options.map(&:last)).to eq([ada_rec.id, zebra_rec.id])
      expect(options.map(&:first)).to eq([
        "Anderson, Ada - ada@example.com (recommender: Ann Rec)",
        "Zebra, Zed - zebra@example.com (recommender: Zed Rec)"
      ])
    end

    it "keeps an older persisted recommendation selectable via include:" do
      current_enrollment = create(:enrollment, user: create(:user, :with_applicant_detail), campyear: camp_config.camp_year)
      older_enrollment = create(:enrollment, user: create(:user, :with_applicant_detail), campyear: camp_config.camp_year - 1)
      current = create(:recommendation, enrollment: current_enrollment)
      older = create(:recommendation, enrollment: older_enrollment)

      options = described_class.current_camp(include: older)

      expect(options.map(&:last)).to contain_exactly(current.id, older.id)
    end

    it "does not duplicate a recommendation that is already in the current-year set" do
      enrollment = create(:enrollment, user: create(:user, :with_applicant_detail), campyear: camp_config.camp_year)
      recommendation = create(:recommendation, enrollment: enrollment)

      options = described_class.current_camp(include: recommendation)

      expect(options.map(&:last)).to eq([recommendation.id])
    end
  end
end
