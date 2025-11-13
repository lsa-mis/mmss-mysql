# frozen_string_literal: true

# == Schema Information
#
# Table name: session_activities
#
#  id                 :bigint           not null, primary key
#  enrollment_id      :bigint           not null
#  camp_occurrence_id :bigint           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
require 'rails_helper'

RSpec.describe SessionActivity, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:enrollment) }
    it { is_expected.to belong_to(:camp_occurrence) }
  end

  describe 'validations' do
    subject { build(:session_activity) }

    # Note: belongs_to associations are automatically validated by Rails
    # The belong_to matcher already tests this validation
  end

  describe 'database columns' do
    it { is_expected.to have_db_column(:id).of_type(:integer) }
    it { is_expected.to have_db_column(:enrollment_id).of_type(:integer) }
    it { is_expected.to have_db_column(:camp_occurrence_id).of_type(:integer) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime) }
  end

  describe 'database indexes' do
    it { is_expected.to have_db_index(:enrollment_id) }
    it { is_expected.to have_db_index(:camp_occurrence_id) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      session_activity = build(:session_activity)
      expect(session_activity).to be_valid
    end

    it 'creates a session_activity with enrollment and camp_occurrence' do
      session_activity = create(:session_activity)
      expect(session_activity.enrollment).to be_present
      expect(session_activity.camp_occurrence).to be_present
      expect(session_activity).to be_persisted
    end
  end

  describe 'ransackable_associations' do
    it 'returns the correct associations' do
      expect(described_class.ransackable_associations).to match_array(['camp_occurrence', 'enrollment'])
    end

    it 'accepts an auth_object parameter' do
      expect { described_class.ransackable_associations(nil) }.not_to raise_error
      expect { described_class.ransackable_associations(double) }.not_to raise_error
    end
  end

  describe 'ransackable_attributes' do
    it 'returns the correct attributes' do
      expected_attributes = ['camp_occurrence_id', 'created_at', 'enrollment_id', 'id', 'updated_at']
      expect(described_class.ransackable_attributes).to match_array(expected_attributes)
    end

    it 'accepts an auth_object parameter' do
      expect { described_class.ransackable_attributes(nil) }.not_to raise_error
      expect { described_class.ransackable_attributes(double) }.not_to raise_error
    end
  end

  describe 'creation and persistence' do
    let(:enrollment) { create(:enrollment) }
    let(:camp_occurrence) { create(:camp_occurrence) }

    it 'can be created with valid enrollment and camp_occurrence' do
      session_activity = SessionActivity.create(
        enrollment: enrollment,
        camp_occurrence: camp_occurrence
      )
      expect(session_activity).to be_persisted
      expect(session_activity).to be_valid
    end

    it 'cannot be created without an enrollment' do
      session_activity = SessionActivity.new(camp_occurrence: camp_occurrence)
      expect(session_activity).not_to be_valid
      expect(session_activity.errors[:enrollment]).to include("must exist")
    end

    it 'cannot be created without a camp_occurrence' do
      session_activity = SessionActivity.new(enrollment: enrollment)
      expect(session_activity).not_to be_valid
      expect(session_activity.errors[:camp_occurrence]).to include("must exist")
    end
  end

  describe 'associations behavior' do
    let(:enrollment) { create(:enrollment) }
    let(:camp_occurrence) { create(:camp_occurrence) }
    let(:session_activity) { create(:session_activity, enrollment: enrollment, camp_occurrence: camp_occurrence) }

    it 'belongs to the correct enrollment' do
      expect(session_activity.enrollment).to eq(enrollment)
      expect(enrollment.session_activities).to include(session_activity)
    end

    it 'belongs to the correct camp_occurrence' do
      expect(session_activity.camp_occurrence).to eq(camp_occurrence)
      expect(camp_occurrence.session_activities).to include(session_activity)
    end

    it 'can access enrollment through association' do
      expect(session_activity.enrollment).to be_a(Enrollment)
      expect(session_activity.enrollment.id).to eq(enrollment.id)
    end

    it 'can access camp_occurrence through association' do
      expect(session_activity.camp_occurrence).to be_a(CampOccurrence)
      expect(session_activity.camp_occurrence.id).to eq(camp_occurrence.id)
    end
  end

  describe 'timestamps' do
    let(:session_activity) { create(:session_activity) }

    it 'sets created_at on creation' do
      expect(session_activity.created_at).to be_present
      expect(session_activity.created_at).to be_within(1.second).of(Time.current)
    end

    it 'sets updated_at on creation' do
      expect(session_activity.updated_at).to be_present
      expect(session_activity.updated_at).to be_within(1.second).of(Time.current)
    end

    it 'updates updated_at when record is modified' do
      original_updated_at = session_activity.updated_at
      sleep(1) # Ensure time difference
      session_activity.touch
      expect(session_activity.updated_at).to be > original_updated_at
    end
  end

  describe 'multiple session_activities' do
    let(:enrollment) { create(:enrollment) }
    let(:camp_occurrence1) { create(:camp_occurrence) }
    let(:camp_occurrence2) { create(:camp_occurrence) }

    it 'allows an enrollment to have multiple camp_occurrences' do
      # Clear any existing session_activities for this enrollment
      SessionActivity.where(enrollment: enrollment).destroy_all

      sa1 = create(:session_activity, enrollment: enrollment, camp_occurrence: camp_occurrence1)
      sa2 = create(:session_activity, enrollment: enrollment, camp_occurrence: camp_occurrence2)

      expect(enrollment.session_activities.count).to eq(2)
      expect(enrollment.session_activities).to include(sa1, sa2)
    end

    it 'allows a camp_occurrence to be associated with multiple enrollments' do
      enrollment1 = create(:enrollment)
      enrollment2 = create(:enrollment)

      # Clear any existing session_activities for this camp_occurrence
      SessionActivity.where(camp_occurrence: camp_occurrence1).destroy_all

      sa1 = create(:session_activity, enrollment: enrollment1, camp_occurrence: camp_occurrence1)
      sa2 = create(:session_activity, enrollment: enrollment2, camp_occurrence: camp_occurrence1)

      expect(camp_occurrence1.session_activities.count).to eq(2)
      expect(camp_occurrence1.session_activities).to include(sa1, sa2)
    end
  end

  describe 'dependent associations' do
    let(:enrollment) { create(:enrollment) }
    let(:camp_occurrence) { create(:camp_occurrence) }

    it 'is destroyed when enrollment is destroyed' do
      session_activity = create(:session_activity, enrollment: enrollment, camp_occurrence: camp_occurrence)
      enrollment.destroy

      expect(SessionActivity.find_by(id: session_activity.id)).to be_nil
    end

    it 'is destroyed when camp_occurrence is destroyed' do
      session_activity = create(:session_activity, enrollment: enrollment, camp_occurrence: camp_occurrence)
      camp_occurrence.destroy

      expect(SessionActivity.find_by(id: session_activity.id)).to be_nil
    end
  end

  describe 'uniqueness constraints' do
    let(:enrollment) { create(:enrollment) }
    let(:camp_occurrence) { create(:camp_occurrence) }

    context 'when creating duplicate session_activities' do
      it 'allows the same enrollment and camp_occurrence combination multiple times' do
        create(:session_activity, enrollment: enrollment, camp_occurrence: camp_occurrence)
        sa2 = build(:session_activity, enrollment: enrollment, camp_occurrence: camp_occurrence)

        # Note: Based on the schema, there's no uniqueness constraint
        # So this should be valid if the model allows it
        expect(sa2).to be_valid
      end
    end
  end

  describe 'querying and scopes' do
    let(:enrollment1) { create(:enrollment) }
    let(:enrollment2) { create(:enrollment) }
    let(:camp_occurrence1) { create(:camp_occurrence) }
    let(:camp_occurrence2) { create(:camp_occurrence) }

    before do
      # Clear any existing session_activities for these records
      SessionActivity.where(enrollment: [enrollment1, enrollment2]).destroy_all
      SessionActivity.where(camp_occurrence: [camp_occurrence1, camp_occurrence2]).destroy_all

      create(:session_activity, enrollment: enrollment1, camp_occurrence: camp_occurrence1)
      create(:session_activity, enrollment: enrollment1, camp_occurrence: camp_occurrence2)
      create(:session_activity, enrollment: enrollment2, camp_occurrence: camp_occurrence1)
    end

    it 'can find session_activities by enrollment' do
      expect(SessionActivity.where(enrollment: enrollment1).count).to eq(2)
    end

    it 'can find session_activities by camp_occurrence' do
      expect(SessionActivity.where(camp_occurrence: camp_occurrence1).count).to eq(2)
    end

    it 'can find session_activities by both enrollment and camp_occurrence' do
      expect(SessionActivity.where(enrollment: enrollment1, camp_occurrence: camp_occurrence1).count).to eq(1)
    end
  end

  it_behaves_like 'a model with timestamps'
end
