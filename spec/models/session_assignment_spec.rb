# frozen_string_literal: true

# == Schema Information
#
# Table name: session_assignments
#
#  id                 :bigint           not null, primary key
#  enrollment_id      :bigint           not null
#  camp_occurrence_id :bigint           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  offer_status       :string(255)
#
require 'rails_helper'

RSpec.describe SessionAssignment, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:enrollment) }
    it { is_expected.to belong_to(:camp_occurrence) }
    it { is_expected.to have_many(:course_assignments).through(:enrollment) }
    it { is_expected.to have_many(:wait_list_assignments).through(:enrollment).source(:course_assignments) }
  end

  describe 'scopes' do
    let!(:active_camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year) }
    let!(:inactive_camp_config) { create(:camp_configuration, camp_year: Date.current.year - 1) }

    let!(:current_year_enrollment) { create(:enrollment, campyear: Date.current.year) }
    let!(:previous_year_enrollment) { create(:enrollment, campyear: Date.current.year - 1) }

    let!(:current_session) { create(:camp_occurrence, camp_configuration: active_camp_config) }
    let!(:previous_session) { create(:camp_occurrence, camp_configuration: inactive_camp_config) }

    let!(:current_year_assignment) do
      create(:session_assignment,
             enrollment: current_year_enrollment,
             camp_occurrence: current_session,
             offer_status: 'accepted')
    end

    let!(:previous_year_assignment) do
      create(:session_assignment,
             enrollment: previous_year_enrollment,
             camp_occurrence: previous_session,
             offer_status: 'accepted')
    end

    describe '.current_year_session_assignments' do
      it 'returns only assignments for current camp year enrollments' do
        expect(described_class.current_year_session_assignments).to include(current_year_assignment)
        expect(described_class.current_year_session_assignments).not_to include(previous_year_assignment)
      end
    end

    describe '.accepted' do
      let!(:pending_assignment) do
        create(:session_assignment,
               enrollment: current_year_enrollment,
               camp_occurrence: current_session,
               offer_status: nil)
      end

      let!(:declined_assignment) do
        create(:session_assignment,
               enrollment: current_year_enrollment,
               camp_occurrence: current_session,
               offer_status: 'declined')
      end

      it 'returns only accepted assignments for current year' do
        accepted = described_class.accepted
        expect(accepted).to include(current_year_assignment)
        expect(accepted).not_to include(previous_year_assignment)
        expect(accepted).not_to include(pending_assignment)
        expect(accepted).not_to include(declined_assignment)
      end
    end
  end

  describe '#accept_offer!' do
    let(:user) { create(:user) }
    let(:enrollment) { create(:enrollment, user: user) }
    let(:camp_occurrence) { create(:camp_occurrence) }
    let(:session_assignment) do
      create(:session_assignment,
             enrollment: enrollment,
             camp_occurrence: camp_occurrence,
             offer_status: nil)
    end

    context 'when successful' do
      before do
        allow(CourseAssignment).to receive(:handle_session_acceptance).and_return(true)
        allow(enrollment).to receive(:update_status_based_on_session_assignments!).and_return(true)
      end

      it 'updates offer_status to accepted' do
        expect {
          session_assignment.accept_offer!(user)
        }.to change { session_assignment.reload.offer_status }.from(nil).to('accepted')
      end

      it 'calls CourseAssignment.handle_session_acceptance' do
        expect(CourseAssignment).to receive(:handle_session_acceptance).with(session_assignment, user)
        session_assignment.accept_offer!(user)
      end

      it 'calls enrollment.update_status_based_on_session_assignments!' do
        expect(enrollment).to receive(:update_status_based_on_session_assignments!)
        session_assignment.accept_offer!(user)
      end

      it 'wraps operations in a transaction' do
        expect(SessionAssignment).to receive(:transaction).and_call_original
        session_assignment.accept_offer!(user)
      end
    end

    context 'when CourseAssignment.handle_session_acceptance fails' do
      before do
        allow(CourseAssignment).to receive(:handle_session_acceptance).and_raise(StandardError.new('Error'))
      end

      it 'rolls back the transaction' do
        original_status = session_assignment.offer_status
        expect {
          session_assignment.accept_offer!(user) rescue nil
        }.not_to(change { session_assignment.reload.offer_status })
        expect(session_assignment.offer_status).to eq(original_status)
      end
    end

    context 'when update! fails' do
      before do
        allow(session_assignment).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(session_assignment))
      end

      it 'rolls back the transaction' do
        expect {
          session_assignment.accept_offer!(user) rescue nil
        }.not_to(change { CourseAssignment.count })
      end
    end

    context 'with existing course assignments' do
      let(:course) { create(:course, camp_occurrence: camp_occurrence) }
      let!(:course_assignment) do
        create(:course_assignment,
               enrollment: enrollment,
               course: course,
               wait_list: false)
      end

      it 'sends offer accepted email' do
        expect(OfferMailer).to receive(:offer_accepted_email)
          .with(user.id, session_assignment, course_assignment)
          .and_return(double(deliver_now: true))

        session_assignment.accept_offer!(user)
      end
    end

    context 'without course assignments' do
      it 'handles missing course assignment gracefully' do
        expect(OfferMailer).to receive(:offer_accepted_email)
          .with(user.id, session_assignment, nil)
          .and_return(double(deliver_now: true))

        expect {
          session_assignment.accept_offer!(user)
        }.not_to raise_error
      end
    end
  end

  describe '#decline_offer!' do
    let(:user) { create(:user) }
    let(:enrollment) { create(:enrollment, user: user) }
    let(:camp_occurrence) { create(:camp_occurrence) }
    let(:session_assignment) do
      create(:session_assignment,
             enrollment: enrollment,
             camp_occurrence: camp_occurrence,
             offer_status: nil)
    end

    context 'when successful' do
      before do
        allow(CourseAssignment).to receive(:handle_session_declination).and_return(true)
        allow(enrollment).to receive(:update_status_based_on_session_assignments!).and_return(true)
      end

      it 'updates offer_status to declined' do
        expect {
          session_assignment.decline_offer!(user)
        }.to change { session_assignment.reload.offer_status }.from(nil).to('declined')
      end

      it 'calls CourseAssignment.handle_session_declination' do
        expect(CourseAssignment).to receive(:handle_session_declination).with(session_assignment, user)
        session_assignment.decline_offer!(user)
      end

      it 'calls enrollment.update_status_based_on_session_assignments!' do
        expect(enrollment).to receive(:update_status_based_on_session_assignments!)
        session_assignment.decline_offer!(user)
      end

      it 'wraps operations in a transaction' do
        expect(SessionAssignment).to receive(:transaction).and_call_original
        session_assignment.decline_offer!(user)
      end
    end

    context 'when CourseAssignment.handle_session_declination fails' do
      before do
        allow(CourseAssignment).to receive(:handle_session_declination).and_raise(StandardError.new('Error'))
      end

      it 'rolls back the transaction' do
        original_status = session_assignment.offer_status
        expect {
          session_assignment.decline_offer!(user) rescue nil
        }.not_to(change { session_assignment.reload.offer_status })
        expect(session_assignment.offer_status).to eq(original_status)
      end
    end

    context 'when update! fails' do
      before do
        allow(session_assignment).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(session_assignment))
      end

      it 'rolls back the transaction' do
        expect {
          session_assignment.decline_offer!(user) rescue nil
        }.not_to(change { CourseAssignment.count })
      end
    end

    context 'with existing course assignments' do
      let(:course) { create(:course, camp_occurrence: camp_occurrence) }
      let!(:confirmed_assignment) do
        create(:course_assignment,
               enrollment: enrollment,
               course: course,
               wait_list: false)
      end
      let!(:waitlist_assignment) do
        create(:course_assignment,
               enrollment: enrollment,
               course: course,
               wait_list: true)
      end

      it 'removes course assignments' do
        expect {
          session_assignment.decline_offer!(user)
        }.to change { CourseAssignment.where(enrollment: enrollment, course: course).count }.by(-2)
      end

      it 'sends offer declined email' do
        expect(OfferMailer).to receive(:offer_declined_email)
          .with(user.id, session_assignment, confirmed_assignment)
          .and_return(double(deliver_now: true))

        session_assignment.decline_offer!(user)
      end
    end

    context 'without course assignments' do
      it 'handles missing course assignment gracefully' do
        expect(OfferMailer).to receive(:offer_declined_email)
          .with(user.id, session_assignment, nil)
          .and_return(double(deliver_now: true))

        expect {
          session_assignment.decline_offer!(user)
        }.not_to raise_error
      end
    end
  end

  describe 'ransackable methods' do
    describe '.ransackable_associations' do
      it 'returns the correct associations' do
        expect(described_class.ransackable_associations).to match_array(['camp_occurrence', 'enrollment'])
      end
    end

    describe '.ransackable_attributes' do
      it 'returns the correct attributes' do
        expected_attributes = [
          'camp_occurrence_id',
          'created_at',
          'enrollment_id',
          'id',
          'offer_status',
          'updated_at'
        ]
        expect(described_class.ransackable_attributes).to match_array(expected_attributes)
      end
    end
  end

  describe 'wait_list_assignments association' do
    let(:enrollment) { create(:enrollment) }
    let(:camp_occurrence) { create(:camp_occurrence) }
    let(:session_assignment) { create(:session_assignment, enrollment: enrollment, camp_occurrence: camp_occurrence) }
    let(:course) { create(:course, camp_occurrence: camp_occurrence) }

    let!(:confirmed_assignment) do
      create(:course_assignment,
             enrollment: enrollment,
             course: course,
             wait_list: false)
    end

    let!(:waitlist_assignment) do
      create(:course_assignment,
             enrollment: enrollment,
             course: course,
             wait_list: true)
    end

    it 'returns only wait list course assignments' do
      expect(session_assignment.wait_list_assignments).to include(waitlist_assignment)
      expect(session_assignment.wait_list_assignments).not_to include(confirmed_assignment)
    end
  end

  describe 'course_assignments association' do
    let(:enrollment) { create(:enrollment) }
    let(:camp_occurrence) { create(:camp_occurrence) }
    let(:session_assignment) { create(:session_assignment, enrollment: enrollment, camp_occurrence: camp_occurrence) }
    let(:course) { create(:course, camp_occurrence: camp_occurrence) }

    let!(:course_assignment) do
      create(:course_assignment,
             enrollment: enrollment,
             course: course)
    end

    it 'returns all course assignments for the enrollment' do
      expect(session_assignment.course_assignments).to include(course_assignment)
    end
  end

  describe 'integration with enrollment status updates' do
    let(:user) { create(:user) }
    let(:enrollment) { create(:enrollment, user: user) }
    let(:session1) { create(:camp_occurrence) }
    let(:session2) { create(:camp_occurrence) }

    let!(:assignment1) do
      create(:session_assignment,
             enrollment: enrollment,
             camp_occurrence: session1,
             offer_status: nil)
    end

    let!(:assignment2) do
      create(:session_assignment,
             enrollment: enrollment,
             camp_occurrence: session2,
             offer_status: nil)
    end

    context 'when all assignments are accepted' do
      it 'updates enrollment status to accepted' do
        assignment1.accept_offer!(user)
        assignment2.accept_offer!(user)

        enrollment.reload
        expect(enrollment.offer_status).to eq('accepted')
        expect(enrollment.application_status).to eq('offer accepted')
      end
    end

    context 'when all assignments are declined' do
      it 'updates enrollment status to declined' do
        assignment1.decline_offer!(user)
        assignment2.decline_offer!(user)

        enrollment.reload
        expect(enrollment.offer_status).to eq('declined')
        expect(enrollment.application_status).to eq('offer declined')
      end
    end

    context 'when assignments have mixed statuses' do
      it 'does not update enrollment status until all are responded' do
        assignment1.accept_offer!(user)
        enrollment.reload
        expect(enrollment.offer_status).not_to eq('accepted')

        assignment2.accept_offer!(user)
        enrollment.reload
        expect(enrollment.offer_status).to eq('accepted')
      end
    end
  end

  describe 'validations' do
    it 'requires an enrollment' do
      assignment = build(:session_assignment, enrollment: nil)
      expect(assignment).not_to be_valid
      expect(assignment.errors[:enrollment]).to be_present
    end

    it 'requires a camp_occurrence' do
      assignment = build(:session_assignment, camp_occurrence: nil)
      expect(assignment).not_to be_valid
      expect(assignment.errors[:camp_occurrence]).to be_present
    end
  end

  describe 'offer_status values' do
    let(:enrollment) { create(:enrollment) }
    let(:camp_occurrence) { create(:camp_occurrence) }

    it 'can be nil (pending)' do
      assignment = create(:session_assignment, enrollment: enrollment, camp_occurrence: camp_occurrence, offer_status: nil)
      expect(assignment.offer_status).to be_nil
      expect(assignment).to be_valid
    end

    it 'can be accepted' do
      assignment = create(:session_assignment, enrollment: enrollment, camp_occurrence: camp_occurrence, offer_status: 'accepted')
      expect(assignment.offer_status).to eq('accepted')
      expect(assignment).to be_valid
    end

    it 'can be declined' do
      assignment = create(:session_assignment, enrollment: enrollment, camp_occurrence: camp_occurrence, offer_status: 'declined')
      expect(assignment.offer_status).to eq('declined')
      expect(assignment).to be_valid
    end
  end
end
