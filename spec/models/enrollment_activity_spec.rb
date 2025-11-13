# frozen_string_literal: true

# == Schema Information
#
# Table name: enrollment_activities
#
#  id            :bigint           not null, primary key
#  enrollment_id :bigint           not null
#  activity_id   :bigint           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_enrollment_activities_on_activity_id    (activity_id)
#  index_enrollment_activities_on_enrollment_id  (enrollment_id)
#
# Foreign Keys
#
#  fk_rails_...  (activity_id => activities.id)
#  fk_rails_...  (enrollment_id => enrollments.id)
#
require 'rails_helper'

RSpec.describe EnrollmentActivity, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:enrollment) }
    it { is_expected.to belong_to(:activity) }
  end

  describe 'validations' do
    subject { build(:enrollment_activity) }

    it { is_expected.to validate_presence_of(:enrollment) }
    it { is_expected.to validate_presence_of(:activity) }
  end

  describe 'database columns' do
    it { is_expected.to have_db_column(:id).of_type(:integer) }
    it { is_expected.to have_db_column(:enrollment_id).of_type(:integer) }
    it { is_expected.to have_db_column(:activity_id).of_type(:integer) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime) }
  end

  describe 'database indexes' do
    it { is_expected.to have_db_index(:enrollment_id) }
    it { is_expected.to have_db_index(:activity_id) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      enrollment_activity = build(:enrollment_activity)
      expect(enrollment_activity).to be_valid
    end

    it 'creates an enrollment_activity with enrollment and activity' do
      enrollment_activity = create(:enrollment_activity)
      expect(enrollment_activity.enrollment).to be_present
      expect(enrollment_activity.activity).to be_present
      expect(enrollment_activity).to be_persisted
    end
  end

  describe 'ransackable_associations' do
    it 'returns the correct associations' do
      expect(described_class.ransackable_associations).to match_array(['activity', 'enrollment'])
    end

    it 'accepts an auth_object parameter' do
      expect { described_class.ransackable_associations(nil) }.not_to raise_error
      expect { described_class.ransackable_associations(double) }.not_to raise_error
    end
  end

  describe 'ransackable_attributes' do
    it 'returns the correct attributes' do
      expected_attributes = ['activity_id', 'created_at', 'enrollment_id', 'id', 'updated_at']
      expect(described_class.ransackable_attributes).to match_array(expected_attributes)
    end

    it 'accepts an auth_object parameter' do
      expect { described_class.ransackable_attributes(nil) }.not_to raise_error
      expect { described_class.ransackable_attributes(double) }.not_to raise_error
    end
  end

  describe 'creation and persistence' do
    let(:enrollment) { create(:enrollment) }
    let(:activity) { create(:activity) }

    it 'can be created with valid enrollment and activity' do
      enrollment_activity = EnrollmentActivity.create(
        enrollment: enrollment,
        activity: activity
      )
      expect(enrollment_activity).to be_persisted
      expect(enrollment_activity).to be_valid
    end

    it 'cannot be created without an enrollment' do
      enrollment_activity = EnrollmentActivity.new(activity: activity)
      expect(enrollment_activity).not_to be_valid
      expect(enrollment_activity.errors[:enrollment]).to include("can't be blank")
    end

    it 'cannot be created without an activity' do
      enrollment_activity = EnrollmentActivity.new(enrollment: enrollment)
      expect(enrollment_activity).not_to be_valid
      expect(enrollment_activity.errors[:activity]).to include("can't be blank")
    end
  end

  describe 'associations behavior' do
    let(:enrollment) { create(:enrollment) }
    let(:activity) { create(:activity) }
    let(:enrollment_activity) { create(:enrollment_activity, enrollment: enrollment, activity: activity) }

    it 'belongs to the correct enrollment' do
      expect(enrollment_activity.enrollment).to eq(enrollment)
      expect(enrollment.enrollment_activities).to include(enrollment_activity)
    end

    it 'belongs to the correct activity' do
      expect(enrollment_activity.activity).to eq(activity)
      expect(activity.enrollment_activities).to include(enrollment_activity)
    end

    it 'can access enrollment through association' do
      expect(enrollment_activity.enrollment).to be_a(Enrollment)
      expect(enrollment_activity.enrollment.id).to eq(enrollment.id)
    end

    it 'can access activity through association' do
      expect(enrollment_activity.activity).to be_a(Activity)
      expect(enrollment_activity.activity.id).to eq(activity.id)
    end
  end

  describe 'timestamps' do
    let(:enrollment_activity) { create(:enrollment_activity) }

    it 'sets created_at on creation' do
      expect(enrollment_activity.created_at).to be_present
      expect(enrollment_activity.created_at).to be_within(1.second).of(Time.current)
    end

    it 'sets updated_at on creation' do
      expect(enrollment_activity.updated_at).to be_present
      expect(enrollment_activity.updated_at).to be_within(1.second).of(Time.current)
    end

    it 'updates updated_at when record is modified' do
      original_updated_at = enrollment_activity.updated_at
      sleep(1) # Ensure time difference
      enrollment_activity.touch
      expect(enrollment_activity.updated_at).to be > original_updated_at
    end
  end

  describe 'multiple enrollment_activities' do
    let(:enrollment) { create(:enrollment) }
    let(:activity1) { create(:activity) }
    let(:activity2) { create(:activity) }

    it 'allows an enrollment to have multiple activities' do
      ea1 = create(:enrollment_activity, enrollment: enrollment, activity: activity1)
      ea2 = create(:enrollment_activity, enrollment: enrollment, activity: activity2)

      expect(enrollment.enrollment_activities.count).to eq(2)
      expect(enrollment.enrollment_activities).to include(ea1, ea2)
    end

    it 'allows an activity to be associated with multiple enrollments' do
      enrollment1 = create(:enrollment)
      enrollment2 = create(:enrollment)

      ea1 = create(:enrollment_activity, enrollment: enrollment1, activity: activity1)
      ea2 = create(:enrollment_activity, enrollment: enrollment2, activity: activity1)

      expect(activity1.enrollment_activities.count).to eq(2)
      expect(activity1.enrollment_activities).to include(ea1, ea2)
    end
  end

  describe 'dependent associations' do
    let(:enrollment) { create(:enrollment) }
    let(:activity) { create(:activity) }

    it 'is destroyed when enrollment is destroyed' do
      enrollment_activity = create(:enrollment_activity, enrollment: enrollment, activity: activity)
      enrollment_id = enrollment.id
      enrollment.destroy

      expect(EnrollmentActivity.find_by(id: enrollment_activity.id)).to be_nil
    end

    it 'is destroyed when activity is destroyed' do
      enrollment_activity = create(:enrollment_activity, enrollment: enrollment, activity: activity)
      activity_id = activity.id
      activity.destroy

      expect(EnrollmentActivity.find_by(id: enrollment_activity.id)).to be_nil
    end
  end

  it_behaves_like 'a model with timestamps'
end
