# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::ApplicationsHelper, type: :helper do
  describe '#admin_applicant_name' do
    it 'uses the applicant full name when present' do
      user = build_stubbed(:user, email: 'camper@example.com')
      detail = build_stubbed(:applicant_detail, user: user, firstname: 'Grace', lastname: 'Hopper')
      enrollment = build_stubbed(:enrollment, user: user)
      allow(enrollment).to receive(:applicant_detail).and_return(detail)

      expect(helper.admin_applicant_name(enrollment)).to eq('Hopper, Grace')
    end

    it 'falls back to the account email when applicant details are missing' do
      user = build_stubbed(:user, email: 'missing-detail@example.com')
      enrollment = build_stubbed(:enrollment, user: user)
      allow(enrollment).to receive(:applicant_detail).and_return(nil)

      expect(helper.admin_applicant_name(enrollment)).to eq('missing-detail@example.com')
    end
  end

  describe '#admin_application_session_options' do
    it 'unions session registrations with assigned sessions and sorts by description' do
      session_a = build_stubbed(:camp_occurrence, description: 'Session B')
      session_b = build_stubbed(:camp_occurrence, description: 'Session A')
      assigned = build_stubbed(:camp_occurrence, description: 'Session C')
      assignment = double('SessionAssignment', camp_occurrence: assigned)

      application = build_stubbed(:enrollment)
      allow(application).to receive(:session_registrations).and_return([session_a, session_b])
      allow(application).to receive(:session_assignments).and_return([assignment])

      expect(helper.admin_application_session_options(application)).to eq(
        [
          ['Session A', session_b.id],
          ['Session B', session_a.id],
          ['Session C', assigned.id]
        ]
      )
    end
  end

  describe '#admin_application_course_options' do
    it 'annotates ranked courses with session, rank, and remaining seats' do
      session = build_stubbed(:camp_occurrence, description: 'Session 1')
      course = build_stubbed(:course, title: 'Number Theory', camp_occurrence: session)
      allow(course).to receive(:remaining_spaces).and_return(4)

      preference = build_stubbed(:course_preference, course: course, ranking: 2)
      rankings_relation = double('CoursePreferences')
      allow(rankings_relation).to receive(:index_by).and_return({ course.id => preference })

      registrations = double('CourseRegistrations')
      allow(registrations).to receive(:includes).with(:camp_occurrence).and_return(registrations)
      allow(registrations).to receive(:order).with(:camp_occurrence_id).and_return(registrations)
      allow(registrations).to receive(:to_a).and_return([course])

      application = build_stubbed(:enrollment)
      allow(application).to receive(:course_preferences).and_return(rankings_relation)
      allow(application).to receive(:course_registrations).and_return(registrations)
      allow(application).to receive(:course_assignments).and_return([])

      expect(helper.admin_application_course_options(application)).to eq(
        [['Number Theory, Session 1, rank - 2, available - 4', course.id]]
      )
    end

    it 'includes assigned courses missing from registrations and uses an em dash for unranked courses' do
      session = build_stubbed(:camp_occurrence, description: 'Session 2')
      assigned_course = build_stubbed(:course, title: 'Geometry', camp_occurrence: session)
      allow(assigned_course).to receive(:remaining_spaces).and_return(0)
      assignment = double('CourseAssignment', course: assigned_course)

      rankings_relation = double('CoursePreferences')
      allow(rankings_relation).to receive(:index_by).and_return({})

      registrations = double('CourseRegistrations')
      allow(registrations).to receive(:includes).with(:camp_occurrence).and_return(registrations)
      allow(registrations).to receive(:order).with(:camp_occurrence_id).and_return(registrations)
      allow(registrations).to receive(:to_a).and_return([])

      application = build_stubbed(:enrollment)
      allow(application).to receive(:course_preferences).and_return(rankings_relation)
      allow(application).to receive(:course_registrations).and_return(registrations)
      allow(application).to receive(:course_assignments).and_return([assignment])

      expect(helper.admin_application_course_options(application)).to eq(
        [['Geometry, Session 2, rank - —, available - 0', assigned_course.id]]
      )
    end
  end

  describe '#admin_application_status_options' do
    it 'returns the admin STATUS_OPTIONS for a blank status' do
      application = build_stubbed(:enrollment, application_status: nil)

      expect(helper.admin_application_status_options(application))
        .to eq(Admin::ApplicationsController::STATUS_OPTIONS)
    end

    it 'appends a persisted status that is not in STATUS_OPTIONS so the select cannot clear it' do
      application = build_stubbed(:enrollment, application_status: 'withdrawn')

      options = helper.admin_application_status_options(application)

      expect(options).to include(*Admin::ApplicationsController::STATUS_OPTIONS)
      expect(options).to include('withdrawn')
      expect(options.count('withdrawn')).to eq(1)
    end

    it 'does not duplicate a status that is already in STATUS_OPTIONS' do
      application = build_stubbed(:enrollment, application_status: 'enrolled')

      expect(helper.admin_application_status_options(application))
        .to eq(Admin::ApplicationsController::STATUS_OPTIONS)
    end
  end
end
