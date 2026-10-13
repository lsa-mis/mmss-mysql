# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::CampnotesHelper, type: :helper do
  describe "#admin_campnote_visible?" do
    it "returns true when now falls inside the open/close window" do
      note = build_stubbed(:campnote, opendate: 1.hour.ago, closedate: 1.hour.from_now)

      expect(helper.admin_campnote_visible?(note)).to be true
    end

    it "returns false when the window is in the past or future" do
      closed = build_stubbed(:campnote, opendate: 2.days.ago, closedate: 1.day.ago)
      upcoming = build_stubbed(:campnote, opendate: 1.day.from_now, closedate: 2.days.from_now)

      expect(helper.admin_campnote_visible?(closed)).to be false
      expect(helper.admin_campnote_visible?(upcoming)).to be false
    end

    it "returns false when opendate or closedate is missing" do
      undated = build_stubbed(:campnote, opendate: nil, closedate: nil)
      half = build_stubbed(:campnote, opendate: 1.hour.ago, closedate: nil)

      expect(helper.admin_campnote_visible?(undated)).to be false
      expect(helper.admin_campnote_visible?(half)).to be false
    end
  end

  describe "#admin_campnote_type_options" do
    it "returns the standard alert/notice types for a blank notetype" do
      note = build_stubbed(:campnote, notetype: nil)

      expect(helper.admin_campnote_type_options(note)).to eq(helper.campnote_types)
    end

    it "appends a legacy notetype so the select cannot clear it" do
      note = build_stubbed(:campnote, notetype: "general")

      options = helper.admin_campnote_type_options(note)

      expect(options).to include(%w[Alert alert], %w[Notice notice])
      expect(options).to include(["General", "general"])
    end

    it "does not duplicate a standard notetype" do
      note = build_stubbed(:campnote, notetype: "alert")

      expect(helper.admin_campnote_type_options(note)).to eq(helper.campnote_types)
    end
  end
end
