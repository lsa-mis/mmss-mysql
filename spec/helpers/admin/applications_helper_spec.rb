# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::ApplicationsHelper, type: :helper do
  describe "#admin_applicant_name" do
    it "uses the applicant full name when present" do
      user = build_stubbed(:user, email: "camper@example.com")
      detail = build_stubbed(:applicant_detail, user: user, firstname: "Grace", lastname: "Hopper")
      enrollment = build_stubbed(:enrollment, user: user)
      allow(enrollment).to receive(:applicant_detail).and_return(detail)

      expect(helper.admin_applicant_name(enrollment)).to eq("Hopper, Grace")
    end

    it "falls back to the account email when applicant details are missing" do
      user = build_stubbed(:user, email: "missing-detail@example.com")
      enrollment = build_stubbed(:enrollment, user: user)
      allow(enrollment).to receive(:applicant_detail).and_return(nil)

      expect(helper.admin_applicant_name(enrollment)).to eq("missing-detail@example.com")
    end
  end

  # The enrollment factory registers every active session and course of the camp; these examples
  # need to control exactly what the application registered for, so they start from a clean slate.
  let(:application) do
    create(:enrollment).tap do |enrollment|
      enrollment.session_activities.delete_all
      enrollment.course_preferences.delete_all
      enrollment.reload
    end
  end
  let(:camp_config) { CampConfiguration.find_by!(camp_year: application.campyear) }

  describe "#admin_application_session_options" do
    it "unions session registrations with assigned sessions and sorts by description" do
      session_b = create(:camp_occurrence, camp_configuration: camp_config, description: "Session B")
      session_a = create(:camp_occurrence, camp_configuration: camp_config, description: "Session A")
      assigned = create(:camp_occurrence, camp_configuration: camp_config, description: "Session C")
      create(:session_activity, enrollment: application, camp_occurrence: session_b)
      create(:session_activity, enrollment: application, camp_occurrence: session_a)
      create(:session_assignment, enrollment: application, camp_occurrence: assigned)

      expect(helper.admin_application_session_options(application)).to eq(
        [
          ["Session A", session_a.id],
          ["Session B", session_b.id],
          ["Session C", assigned.id]
        ]
      )
    end

    it "does not list an assigned session twice when it was also registered" do
      session = create(:camp_occurrence, camp_configuration: camp_config, description: "Session A")
      create(:session_activity, enrollment: application, camp_occurrence: session)
      create(:session_assignment, enrollment: application, camp_occurrence: session)

      expect(helper.admin_application_session_options(application)).to eq([["Session A", session.id]])
    end
  end

  describe "#admin_application_course_options" do
    it "annotates ranked courses with session, rank, and remaining seats" do
      session = create(:camp_occurrence, camp_configuration: camp_config, description: "Session 1")
      course = create(:course, camp_occurrence: session, title: "Number Theory", available_spaces: 5)
      unranked = create(:course, camp_occurrence: session, title: "Algebra", available_spaces: 3)
      create(:course_preference, enrollment: application, course: unranked, ranking: nil)
      create(:course_preference, enrollment: application, course: course, ranking: 2)
      create(:course_assignment, course: course)

      expect(helper.admin_application_course_options(application)).to contain_exactly(
        ["Number Theory, Session 1, rank - 2, available - 4", course.id],
        ["Algebra, Session 1, rank - —, available - 3", unranked.id]
      )
    end

    it "includes assigned courses the applicant never registered for" do
      session = create(:camp_occurrence, camp_configuration: camp_config, description: "Session 2")
      assigned_course = create(:course, camp_occurrence: session, title: "Geometry", available_spaces: 1)
      create(:course_assignment, enrollment: application, course: assigned_course)

      expect(helper.admin_application_course_options(application)).to eq(
        [["Geometry, Session 2, rank - —, available - 0", assigned_course.id]]
      )
    end

    it "does not list an assigned course twice when it was also ranked" do
      session = create(:camp_occurrence, camp_configuration: camp_config, description: "Session 3")
      course = create(:course, camp_occurrence: session, title: "Topology", available_spaces: 3)
      create(:course_preference, enrollment: application, course: course, ranking: 1)
      create(:course_assignment, enrollment: application, course: course)

      expect(helper.admin_application_course_options(application).map(&:last)).to eq([course.id])
    end
  end

  describe "#admin_application_status_options" do
    it "returns the admin STATUS_OPTIONS for a blank status" do
      application = build_stubbed(:enrollment, application_status: nil)

      expect(helper.admin_application_status_options(application))
        .to eq(Admin::ApplicationsController::STATUS_OPTIONS)
    end

    it "appends a persisted status that is not in STATUS_OPTIONS so the select cannot clear it" do
      application = build_stubbed(:enrollment, application_status: "withdrawn")

      options = helper.admin_application_status_options(application)

      expect(options).to include(*Admin::ApplicationsController::STATUS_OPTIONS)
      expect(options).to include("withdrawn")
      expect(options.count("withdrawn")).to eq(1)
    end

    it "does not duplicate a status that is already in STATUS_OPTIONS" do
      application = build_stubbed(:enrollment, application_status: "enrolled")

      expect(helper.admin_application_status_options(application))
        .to eq(Admin::ApplicationsController::STATUS_OPTIONS)
    end
  end
end
