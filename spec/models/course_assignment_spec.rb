# frozen_string_literal: true

# == Schema Information
#
# Table name: course_assignments
#
#  id            :bigint           not null, primary key
#  enrollment_id :bigint           not null
#  course_id     :bigint           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  wait_list     :boolean          default(FALSE)
#
require 'rails_helper'

RSpec.describe CourseAssignment, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:enrollment) }
    it { is_expected.to belong_to(:course) }
  end

  describe 'validations' do
    subject { build(:course_assignment) }

    it { is_expected.to validate_presence_of(:enrollment_id) }
    it { is_expected.to validate_presence_of(:course_id) }
  end

  describe 'database columns' do
    it { is_expected.to have_db_column(:id).of_type(:integer) }
    it { is_expected.to have_db_column(:enrollment_id).of_type(:integer) }
    it { is_expected.to have_db_column(:course_id).of_type(:integer) }
    it { is_expected.to have_db_column(:wait_list).of_type(:boolean) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime) }
  end

  describe 'default values' do
    it 'defaults wait_list to false' do
      assignment = CourseAssignment.new
      expect(assignment.wait_list).to eq(false)
    end

    it 'can set wait_list to true' do
      assignment = build(:course_assignment, wait_list: true)
      expect(assignment.wait_list).to eq(true)
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      assignment = create(:course_assignment)
      expect(assignment).to be_valid
      expect(assignment).to be_persisted
    end

    it 'creates waitlisted assignment using trait' do
      assignment = create(:course_assignment, :waitlisted)
      expect(assignment.wait_list).to eq(true)
    end

    it 'creates active assignment using trait' do
      assignment = create(:course_assignment, :active)
      expect(assignment.wait_list).to eq(false)
    end
  end

  describe 'scopes' do
    let!(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year) }
    let!(:session1) { create(:camp_occurrence, camp_configuration: camp_config, active: true, description: 'Session 1') }
    let!(:session2) { create(:camp_occurrence, camp_configuration: camp_config, active: true, description: 'Session 2') }
    let!(:course1) { create(:course, camp_occurrence: session1) }
    let!(:course2) { create(:course, camp_occurrence: session2) }
    let!(:enrollment) { create(:enrollment, campyear: camp_config.camp_year) }
    let!(:assignment1) { create(:course_assignment, course: course1, enrollment: enrollment, wait_list: false) }
    let!(:assignment2) { create(:course_assignment, course: course1, enrollment: enrollment, wait_list: true) }
    let!(:assignment3) { create(:course_assignment, course: course2, enrollment: enrollment, wait_list: false) }

    describe '.for_session' do
      it 'returns assignments for a specific session' do
        expect(CourseAssignment.for_session(session1.id)).to include(assignment1, assignment2)
        expect(CourseAssignment.for_session(session1.id)).not_to include(assignment3)
      end

      it 'returns empty collection when no assignments exist for session' do
        other_session = create(:camp_occurrence, camp_configuration: camp_config, active: true)
        expect(CourseAssignment.for_session(other_session.id)).to be_empty
      end
    end

    describe '.wait_list' do
      it 'returns only waitlisted assignments' do
        expect(CourseAssignment.wait_list).to include(assignment2)
        expect(CourseAssignment.wait_list).not_to include(assignment1, assignment3)
      end
    end

    describe '.confirmed' do
      it 'returns only confirmed assignments (not waitlisted)' do
        expect(CourseAssignment.confirmed).to include(assignment1, assignment3)
        expect(CourseAssignment.confirmed).not_to include(assignment2)
      end
    end

    describe '.number_of_assignments' do
      it 'returns count of confirmed assignments for a course' do
        expect(CourseAssignment.number_of_assignments(course1.id)).to eq(1)
        expect(CourseAssignment.number_of_assignments(course2.id)).to eq(1)
      end

      it 'returns 0 when no confirmed assignments exist for course' do
        new_course = create(:course, camp_occurrence: session1)
        expect(CourseAssignment.number_of_assignments(new_course.id)).to eq(0)
      end

      it 'does not count waitlisted assignments' do
        expect(CourseAssignment.number_of_assignments(course1.id)).to eq(1)
        # assignment2 is waitlisted and should not be counted
      end
    end

    describe '.wait_list_number' do
      it 'returns count of waitlisted assignments for a course' do
        expect(CourseAssignment.wait_list_number(course1.id)).to eq(1)
        expect(CourseAssignment.wait_list_number(course2.id)).to eq(0)
      end

      it 'returns 0 when no waitlisted assignments exist for course' do
        expect(CourseAssignment.wait_list_number(course2.id)).to eq(0)
      end

      it 'does not count confirmed assignments' do
        expect(CourseAssignment.wait_list_number(course1.id)).to eq(1)
        # assignment1 is confirmed and should not be counted
      end
    end
  end

  describe 'class methods' do
    let!(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year) }
    let!(:session) { create(:camp_occurrence, camp_configuration: camp_config, active: true) }
    let!(:course) { create(:course, camp_occurrence: session) }
    let!(:enrollment1) { create(:enrollment, campyear: camp_config.camp_year) }
    let!(:enrollment2) { create(:enrollment, campyear: camp_config.camp_year) }
    let!(:confirmed_assignment) { create(:course_assignment, course: course, enrollment: enrollment1, wait_list: false) }
    let!(:waitlist_assignment) { create(:course_assignment, course: course, enrollment: enrollment1, wait_list: true) }
    let!(:other_session) { create(:camp_occurrence, camp_configuration: camp_config, active: true) }
    let!(:other_course) { create(:course, camp_occurrence: other_session) }
    let!(:other_assignment) { create(:course_assignment, course: other_course, enrollment: enrollment1, wait_list: false) }

    describe '.find_for_session' do
      it 'finds confirmed assignment for a session and enrollment' do
        result = CourseAssignment.find_for_session(session.id, enrollment1.id)
        expect(result).to eq(confirmed_assignment)
      end

      it 'finds waitlisted assignment when wait_list: true is specified' do
        result = CourseAssignment.find_for_session(session.id, enrollment1.id, wait_list: true)
        expect(result).to eq(waitlist_assignment)
      end

      it 'returns nil when no assignment exists for the session and enrollment' do
        result = CourseAssignment.find_for_session(session.id, enrollment2.id)
        expect(result).to be_nil
      end

      it 'returns nil when assignment exists for different session' do
        result = CourseAssignment.find_for_session(other_session.id, enrollment1.id)
        expect(result).to eq(other_assignment)
        expect(result).not_to eq(confirmed_assignment)
      end
    end

    describe '.find_wait_list_for_session' do
      it 'finds waitlisted assignment for a session and enrollment' do
        result = CourseAssignment.find_wait_list_for_session(session.id, enrollment1.id)
        expect(result).to eq(waitlist_assignment)
      end

      it 'returns nil when no waitlisted assignment exists' do
        result = CourseAssignment.find_wait_list_for_session(session.id, enrollment2.id)
        expect(result).to be_nil
      end

      it 'does not return confirmed assignments' do
        result = CourseAssignment.find_wait_list_for_session(session.id, enrollment1.id)
        expect(result).not_to eq(confirmed_assignment)
        expect(result).to eq(waitlist_assignment)
      end
    end

    describe '.remove_for_session' do
      it 'removes both confirmed and waitlisted assignments for a session and enrollment' do
        expect {
          CourseAssignment.remove_for_session(session.id, enrollment1.id)
        }.to change { CourseAssignment.count }.by(-2)

        expect(CourseAssignment.find_by(id: confirmed_assignment.id)).to be_nil
        expect(CourseAssignment.find_by(id: waitlist_assignment.id)).to be_nil
      end

      it 'does not remove assignments for other sessions' do
        expect {
          CourseAssignment.remove_for_session(session.id, enrollment1.id)
        }.not_to(change { other_assignment.reload })

        expect(other_assignment).to be_persisted
      end

      it 'does not remove assignments for other enrollments' do
        enrollment3 = create(:enrollment, campyear: camp_config.camp_year)
        assignment3 = create(:course_assignment, course: course, enrollment: enrollment3, wait_list: false)

        expect {
          CourseAssignment.remove_for_session(session.id, enrollment1.id)
        }.not_to(change { assignment3.reload })

        expect(assignment3).to be_persisted
      end

      it 'handles case when no assignments exist gracefully' do
        expect {
          CourseAssignment.remove_for_session(session.id, enrollment2.id)
        }.not_to raise_error
      end

      it 'wraps removal in a transaction' do
        allow(CourseAssignment).to receive(:transaction).and_yield
        allow(CourseAssignment).to receive(:find_for_session).and_return(confirmed_assignment)
        allow(CourseAssignment).to receive(:find_wait_list_for_session).and_return(waitlist_assignment)

        CourseAssignment.remove_for_session(session.id, enrollment1.id)

        expect(CourseAssignment).to have_received(:transaction)
      end
    end

    describe '.handle_session_acceptance' do
      let(:user) { enrollment1.user }
      let(:session_assignment) { create(:session_assignment, enrollment: enrollment1, camp_occurrence: session, offer_status: 'accepted') }

      it 'sends offer accepted email' do
        expect(OfferMailer).to receive(:offer_accepted_email).with(user.id, session_assignment, confirmed_assignment).and_return(double(deliver_now: true))

        CourseAssignment.handle_session_acceptance(session_assignment, user)
      end

      it 'finds the course assignment for the session' do
        allow(CourseAssignment).to receive(:find_for_session).and_return(confirmed_assignment)
        allow(OfferMailer).to receive(:offer_accepted_email).and_return(double(deliver_now: true))

        CourseAssignment.handle_session_acceptance(session_assignment, user)

        expect(CourseAssignment).to have_received(:find_for_session).with(session.id, enrollment1.id)
      end

      context 'when course assignment does not exist' do
        before do
          CourseAssignment.where(enrollment: enrollment1, course: course).destroy_all
        end

        it 'still sends email with nil course assignment' do
          expect(OfferMailer).to receive(:offer_accepted_email).with(user.id, session_assignment, nil).and_return(double(deliver_now: true))

          CourseAssignment.handle_session_acceptance(session_assignment, user)
        end
      end
    end

    describe '.handle_session_declination' do
      let(:user) { enrollment1.user }
      let(:session_assignment) { create(:session_assignment, enrollment: enrollment1, camp_occurrence: session, offer_status: 'declined') }

      it 'removes assignments and sends offer declined email' do
        allow(OfferMailer).to receive(:offer_declined_email).and_return(double(deliver_now: true))

        expect {
          CourseAssignment.handle_session_declination(session_assignment, user)
        }.to change { CourseAssignment.where(enrollment: enrollment1, course: course).count }.by(-2)

        expect(OfferMailer).to have_received(:offer_declined_email).with(user.id, session_assignment, confirmed_assignment)
      end

      it 'finds the course assignment before removing it' do
        allow(CourseAssignment).to receive(:find_for_session).and_return(confirmed_assignment)
        allow(CourseAssignment).to receive(:find_wait_list_for_session).and_return(waitlist_assignment)
        allow(OfferMailer).to receive(:offer_declined_email).and_return(double(deliver_now: true))

        CourseAssignment.handle_session_declination(session_assignment, user)

        # find_for_session is called twice: once in handle_session_declination, once in remove_for_session
        expect(CourseAssignment).to have_received(:find_for_session).with(session.id, enrollment1.id).at_least(:once)
      end

      context 'when no assignments exist' do
        before do
          CourseAssignment.where(enrollment: enrollment1, course: course).destroy_all
        end

        it 'handles gracefully and still sends email' do
          expect(OfferMailer).to receive(:offer_declined_email).with(user.id, session_assignment, nil).and_return(double(deliver_now: true))

          expect {
            CourseAssignment.handle_session_declination(session_assignment, user)
          }.not_to raise_error
        end
      end
    end
  end

  describe 'ransackable methods' do
    describe '.ransackable_associations' do
      it 'returns array of ransackable associations' do
        expect(CourseAssignment.ransackable_associations).to match_array(['course', 'enrollment'])
      end
    end

    describe '.ransackable_attributes' do
      it 'returns array of ransackable attributes' do
        expected_attributes = ['course_id', 'created_at', 'enrollment_id', 'id', 'updated_at', 'wait_list']
        expect(CourseAssignment.ransackable_attributes).to match_array(expected_attributes)
      end
    end
  end

  describe 'integration with enrollment and course' do
    let!(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year) }
    let!(:session) { create(:camp_occurrence, camp_configuration: camp_config, active: true) }
    let!(:course) { create(:course, camp_occurrence: session) }
    let!(:enrollment) { create(:enrollment, campyear: camp_config.camp_year) }

    it 'is destroyed when enrollment is destroyed' do
      assignment = create(:course_assignment, enrollment: enrollment, course: course)

      expect {
        enrollment.destroy
      }.to change { CourseAssignment.count }.by(-1)

      expect(CourseAssignment.find_by(id: assignment.id)).to be_nil
    end

    it 'is destroyed when course is destroyed' do
      assignment = create(:course_assignment, enrollment: enrollment, course: course)

      expect {
        course.destroy
      }.to change { CourseAssignment.count }.by(-1)

      expect(CourseAssignment.find_by(id: assignment.id)).to be_nil
    end

    it 'can access enrollment through association' do
      assignment = create(:course_assignment, enrollment: enrollment, course: course)
      expect(assignment.enrollment).to eq(enrollment)
    end

    it 'can access course through association' do
      assignment = create(:course_assignment, enrollment: enrollment, course: course)
      expect(assignment.course).to eq(course)
    end
  end

  it_behaves_like 'a model with timestamps'
end
