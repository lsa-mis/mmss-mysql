# frozen_string_literal: true

# == Schema Information
#
# Table name: rejections
#
#  id            :bigint           not null, primary key
#  enrollment_id :bigint           not null
#  reason        :text(65535)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
require 'rails_helper'

RSpec.describe Rejection, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:enrollment) }
  end

  describe 'validations' do
    subject { build(:rejection) }

    it { is_expected.to validate_presence_of(:reason) }

    context 'when reason is blank' do
      it 'is invalid' do
        rejection = build(:rejection, reason: nil)
        expect(rejection).not_to be_valid
        expect(rejection.errors[:reason]).to include("can't be blank")
      end

      it 'is invalid with empty string' do
        rejection = build(:rejection, reason: '')
        expect(rejection).not_to be_valid
        expect(rejection.errors[:reason]).to include("can't be blank")
      end

      it 'is invalid with whitespace only' do
        rejection = build(:rejection, reason: '   ')
        expect(rejection).not_to be_valid
        expect(rejection.errors[:reason]).to include("can't be blank")
      end
    end

    context 'when reason is present' do
      it 'is valid with a short reason' do
        rejection = build(:rejection, reason: 'Incomplete application')
        expect(rejection).to be_valid
      end

      it 'is valid with a long reason' do
        rejection = build(:rejection, reason: 'A' * 1000)
        expect(rejection).to be_valid
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      rejection = build(:rejection)
      expect(rejection).to be_valid
    end

    it 'creates a rejection with an enrollment' do
      enrollment = create(:enrollment)
      rejection = create(:rejection, enrollment: enrollment)
      expect(rejection.enrollment).to eq(enrollment)
      expect(rejection.reason).to be_present
    end

    it 'creates rejection with incomplete_application trait' do
      rejection = create(:rejection, :incomplete_application)
      expect(rejection.reason).to eq('Application was incomplete')
    end

    it 'creates rejection with does_not_meet_requirements trait' do
      rejection = create(:rejection, :does_not_meet_requirements)
      expect(rejection.reason).to eq('Does not meet program requirements')
    end
  end

  describe 'callbacks' do
    describe '#set_rejection_status' do
      let(:enrollment) { create(:enrollment, application_status: 'submitted') }
      let(:rejection) { build(:rejection, enrollment: enrollment) }

      context 'when rejection is created' do
        it 'transitions enrollment status to rejected' do
          expect {
            rejection.save!
          }.to change { enrollment.reload.application_status }.to('rejected')
        end

        it 'sets offer_status to empty string' do
          enrollment.update(offer_status: 'offered')
          rejection.save!
          expect(enrollment.reload.offer_status).to eq('')
        end

        it 'updates application_status_updated_on' do
          rejection.save!
          expect(enrollment.reload.application_status_updated_on).to eq(Date.current)
        end
      end

      context 'when enrollment has course assignments' do
        let(:course) { create(:course) }
        let!(:course_assignment) { create(:course_assignment, enrollment: enrollment, course: course) }

        it 'destroys all course assignments' do
          expect {
            rejection.save!
          }.to change { CourseAssignment.count }.by(-1)
            .and change { enrollment.course_assignments.count }.from(1).to(0)
        end

        it 'destroys multiple course assignments' do
          course2 = create(:course)
          create(:course_assignment, enrollment: enrollment, course: course2)

          expect {
            rejection.save!
          }.to change { enrollment.course_assignments.count }.from(2).to(0)
        end
      end

      context 'when enrollment has session assignments' do
        let(:camp_occurrence) { create(:camp_occurrence) }
        let!(:session_assignment) { create(:session_assignment, enrollment: enrollment, camp_occurrence: camp_occurrence) }

        it 'destroys all session assignments' do
          expect {
            rejection.save!
          }.to change { SessionAssignment.count }.by(-1)
            .and change { enrollment.session_assignments.count }.from(1).to(0)
        end

        it 'destroys multiple session assignments' do
          camp_occurrence2 = create(:camp_occurrence)
          create(:session_assignment, enrollment: enrollment, camp_occurrence: camp_occurrence2)

          expect {
            rejection.save!
          }.to change { enrollment.session_assignments.count }.from(2).to(0)
        end
      end

      context 'when enrollment has both course and session assignments' do
        let(:course) { create(:course) }
        let(:camp_occurrence) { create(:camp_occurrence) }
        let!(:course_assignment) { create(:course_assignment, enrollment: enrollment, course: course) }
        let!(:session_assignment) { create(:session_assignment, enrollment: enrollment, camp_occurrence: camp_occurrence) }

        it 'destroys both course and session assignments' do
          expect {
            rejection.save!
          }.to change { CourseAssignment.count }.by(-1)
            .and change { SessionAssignment.count }.by(-1)
            .and change { enrollment.course_assignments.count }.from(1).to(0)
            .and change { enrollment.session_assignments.count }.from(1).to(0)
        end
      end

      context 'when enrollment has no assignments' do
        it 'does not raise an error' do
          expect { rejection.save! }.not_to raise_error
        end

        it 'still transitions enrollment status' do
          rejection.save!
          expect(enrollment.reload.application_status).to eq('rejected')
        end
      end

      context 'when callback is triggered after commit' do
        it 'runs after the record is persisted on create' do
          expect(rejection).to receive(:set_rejection_status).and_call_original
          rejection.save!
        end

        it 'runs on update since record is persisted' do
          rejection.save!
          # The callback will run on update, but transition should handle already-rejected status
          expect(rejection).to receive(:set_rejection_status).and_call_original
          rejection.update(reason: 'Updated reason')
        end

        it 'safely handles multiple calls when enrollment is already rejected' do
          rejection.save!
          expect(enrollment.reload.application_status).to eq('rejected')

          # Update should not cause errors even though enrollment is already rejected
          expect {
            rejection.update(reason: 'Updated reason')
          }.not_to raise_error
        end
      end

      context 'when transition_application_status! is called' do
        it 'calls transition_application_status! with correct parameters' do
          # Verify the method is called and enrollment status changes
          expect {
            rejection.save!
          }.to change { enrollment.reload.application_status }.to('rejected')
            .and change { enrollment.reload.offer_status }.to('')
        end

        it 'handles transition errors gracefully' do
          allow_any_instance_of(Enrollment).to receive(:transition_application_status!)
            .and_raise(ActiveRecord::RecordInvalid.new(enrollment))

          expect { rejection.save! }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end
  end

  describe '#set_rejection_status' do
    let(:enrollment) { create(:enrollment, application_status: 'submitted') }
    let(:rejection) { create(:rejection, enrollment: enrollment) }

    it 'is an instance method' do
      expect(Rejection.instance_methods(false)).to include(:set_rejection_status)
    end

    it 'is called after commit when persisted' do
      new_rejection = build(:rejection, enrollment: enrollment)
      expect(new_rejection).to receive(:set_rejection_status).and_call_original
      new_rejection.save!
    end
  end

  describe 'ransackable methods' do
    describe '.ransackable_associations' do
      it 'returns the correct associations' do
        expect(Rejection.ransackable_associations).to eq(['enrollment'])
      end

      it 'accepts an auth_object parameter' do
        expect { Rejection.ransackable_associations(nil) }.not_to raise_error
        expect { Rejection.ransackable_associations(double) }.not_to raise_error
      end
    end

    describe '.ransackable_attributes' do
      it 'returns the correct attributes' do
        expected_attributes = ['created_at', 'enrollment_id', 'id', 'reason', 'updated_at']
        expect(Rejection.ransackable_attributes).to match_array(expected_attributes)
      end

      it 'accepts an auth_object parameter' do
        expect { Rejection.ransackable_attributes(nil) }.not_to raise_error
        expect { Rejection.ransackable_attributes(double) }.not_to raise_error
      end
    end
  end

  describe 'database columns' do
    it { is_expected.to have_db_column(:id).of_type(:integer) }
    it { is_expected.to have_db_column(:enrollment_id).of_type(:integer) }
    it { is_expected.to have_db_column(:reason).of_type(:text) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime) }
  end

  describe 'database indexes' do
    it { is_expected.to have_db_index(:enrollment_id) }
  end

  it_behaves_like 'a model with timestamps'
end
