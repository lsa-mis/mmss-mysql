# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::CampOptions do
  let!(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year) }
  let!(:active_session) do
    create(:camp_occurrence, camp_configuration: camp_config, description: "Session A", active: true)
  end
  let!(:inactive_session) do
    create(:camp_occurrence, :inactive, camp_configuration: camp_config, description: "Session Z")
  end
  let!(:any_session) do
    create(:camp_occurrence, camp_configuration: camp_config, description: "Any Session", active: true)
  end

  describe ".sessions" do
    it "returns active sessions excluding Any Session as [label, id]" do
      options = described_class.sessions

      expect(options.map(&:last)).to eq([active_session.id])
      expect(options.map(&:first)).to eq([active_session.display_name])
      expect(options.map(&:last)).not_to include(any_session.id, inactive_session.id)
    end

    it "keeps an inactive persisted session selectable via include:" do
      options = described_class.sessions(include: inactive_session)

      expect(options.map(&:last)).to contain_exactly(active_session.id, inactive_session.id)
      expect(options.last).to eq([inactive_session.display_name, inactive_session.id])
    end

    it "does not duplicate a session that is already in the active set" do
      options = described_class.sessions(include: active_session)

      expect(options.map(&:last)).to eq([active_session.id])
    end
  end

  describe ".courses" do
    let!(:active_course) { create(:course, camp_occurrence: active_session, title: "Algebra") }
    let!(:inactive_course) { create(:course, camp_occurrence: inactive_session, title: "Legacy Geometry") }

    it "returns courses on active sessions as [label, id]" do
      options = described_class.courses

      expect(options.map(&:last)).to eq([active_course.id])
      expect(options.map(&:first)).to eq([active_course.display_name])
      expect(options.map(&:last)).not_to include(inactive_course.id)
    end

    it "keeps a course from an inactive session selectable via include:" do
      options = described_class.courses(include: inactive_course)

      expect(options.map(&:last)).to contain_exactly(active_course.id, inactive_course.id)
      expect(options.last).to eq([inactive_course.display_name, inactive_course.id])
    end

    it "does not duplicate a course that is already in the active set" do
      options = described_class.courses(include: active_course)

      expect(options.map(&:last)).to eq([active_course.id])
    end
  end

  describe ".activities" do
    let!(:active_activity) { create(:activity, camp_occurrence: active_session, description: "Lab Tour") }
    let!(:inactive_activity) { create(:activity, camp_occurrence: inactive_session, description: "Legacy Hike") }

    it "returns activities on active sessions as [label, id]" do
      options = described_class.activities

      expect(options.map(&:last)).to eq([active_activity.id])
      expect(options.map(&:first)).to eq([active_activity.display_name])
      expect(options.map(&:last)).not_to include(inactive_activity.id)
    end

    it "keeps an activity from an inactive session selectable via include:" do
      options = described_class.activities(include: inactive_activity)

      expect(options.map(&:last)).to contain_exactly(active_activity.id, inactive_activity.id)
      expect(options.last).to eq([inactive_activity.display_name, inactive_activity.id])
    end

    it "does not duplicate an activity that is already in the active set" do
      options = described_class.activities(include: active_activity)

      expect(options.map(&:last)).to eq([active_activity.id])
    end
  end
end
