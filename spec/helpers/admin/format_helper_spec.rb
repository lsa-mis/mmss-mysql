# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::FormatHelper, type: :helper do
  describe "#admin_format_value" do
    it "returns the empty placeholder for nil or blank strings" do
      expect(helper.admin_format_value(nil)).to include(Admin::FormatHelper::EMPTY)
      expect(helper.admin_format_value("")).to include(Admin::FormatHelper::EMPTY)
    end

    it "passes through ActiveSupport::SafeBuffer HTML unchanged" do
      html = helper.tag.span("safe", class: "keep-me")

      expect(helper.admin_format_value(html)).to eq(html)
    end

    it "renders booleans as Yes/No badges" do
      expect(helper.admin_format_value(true)).to include("Yes", "admin-badge-green")
      expect(helper.admin_format_value(false)).to include("No", "admin-badge-gray")
    end

    it "formats Money values with the default currency" do
      expect(helper.admin_format_value(Money.new(1_500, "USD"))).to eq("$15.00")
    end

    it "formats dates and datetimes for admin tables" do
      expect(helper.admin_format_value(Date.new(2026, 7, 4))).to eq("Jul 4, 2026")

      stamped = Time.zone.local(2026, 7, 4, 15, 30)
      expect(helper.admin_format_value(stamped)).to eq("Jul 4, 2026 3:30 PM")
    end

    it "prefers display_name, then falls back to to_s on ActiveRecord values" do
      named = build_stubbed(:user, email: "camper@example.com")
      allow(named).to receive(:display_name).and_return("Camper Display")
      expect(helper.admin_format_value(named)).to eq("Camper Display")

      plain = build_stubbed(:camp_occurrence, description: "Session A")
      allow(plain).to receive(:display_name).and_return(nil)
      expect(helper.admin_format_value(plain)).to eq(plain.to_s)
    end

    it "joins array members with commas, formatting each item" do
      html = helper.admin_format_value([true, Date.new(2026, 1, 2)])

      expect(html).to include("Yes")
      expect(html).to include("Jan 2, 2026")
      expect(html).to include(", ")
    end

    it "stringifies other scalar values" do
      expect(helper.admin_format_value(42)).to eq("42")
      expect(helper.admin_format_value(:pending)).to eq("pending")
    end
  end

  describe "#admin_money_from_cents" do
    it "returns the empty placeholder when cents are blank" do
      expect(helper.admin_money_from_cents(nil)).to include(Admin::FormatHelper::EMPTY)
      expect(helper.admin_money_from_cents("")).to include(Admin::FormatHelper::EMPTY)
    end

    it "formats integer and numeric-string cents as currency" do
      expect(helper.admin_money_from_cents(1_500)).to eq("$15")
      expect(helper.admin_money_from_cents("2500")).to eq("$25")
    end
  end

  describe "#admin_status_badge" do
    it "returns the empty placeholder for blank status" do
      expect(helper.admin_status_badge(nil)).to include(Admin::FormatHelper::EMPTY)
      expect(helper.admin_status_badge("")).to include(Admin::FormatHelper::EMPTY)
    end

    it "maps known statuses onto the matching badge colour" do
      {
        "enrolled" => "green",
        "accepted" => "green",
        "awarded" => "green",
        "open" => "green",
        "offer accepted" => "green",
        "offered" => "blue",
        "application complete" => "blue",
        "pending" => "blue",
        "submitted" => "blue",
        "waitlisted" => "yellow",
        "withdrawn" => "red",
        "rejected" => "red",
        "declined" => "red",
        "offer declined" => "red",
        "closed" => "red"
      }.each do |status, colour|
        html = helper.admin_status_badge(status)

        expect(html).to include(status)
        expect(html).to include("admin-badge-#{colour}"), "#{status.inspect} expected #{colour}"
      end
    end

    it "falls back to a grey badge for unknown statuses" do
      html = helper.admin_status_badge("mystery")

      expect(html).to include("mystery")
      expect(html).to include("admin-badge-gray")
    end
  end

  describe "#admin_date and #admin_datetime" do
    it "return the empty placeholder when the value is blank" do
      expect(helper.admin_date(nil)).to include(Admin::FormatHelper::EMPTY)
      expect(helper.admin_datetime(nil)).to include(Admin::FormatHelper::EMPTY)
    end
  end
end
