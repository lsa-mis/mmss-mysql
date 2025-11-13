# frozen_string_literal: true

# == Schema Information
#
# Table name: course_preferences
#
#  id            :bigint           not null, primary key
#  enrollment_id :bigint           not null
#  course_id     :bigint           not null
#  ranking       :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_course_preferences_on_course_id      (course_id)
#  index_course_preferences_on_enrollment_id  (enrollment_id)
#
# Foreign Keys
#
#  fk_rails_...  (course_id => courses.id)
#  fk_rails_...  (enrollment_id => enrollments.id)
#
require 'rails_helper'

RSpec.describe CoursePreference, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:enrollment) }
    it { is_expected.to belong_to(:course) }

    # Test that the associations are configured with dependent: :destroy
    it 'is configured to be destroyed when enrollment is destroyed' do
      expect(Enrollment.reflect_on_association(:course_preferences).options[:dependent]).to eq(:destroy)
    end

    it 'is configured to be destroyed when course is destroyed' do
      expect(Course.reflect_on_association(:course_preferences).options[:dependent]).to eq(:destroy)
    end
  end

  describe 'validations' do
    subject { build(:course_preference) }

    # Note: enrollment_id and course_id are required at the database level (NOT NULL constraint)
    # but not validated at the model level. The belongs_to associations handle the foreign key constraints.
    it 'requires enrollment_id at database level' do
      preference = build(:course_preference, enrollment: nil)
      expect { preference.save(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end

    it 'requires course_id at database level' do
      preference = build(:course_preference, course: nil)
      expect { preference.save(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end
  end

  describe 'database columns' do
    it { is_expected.to have_db_column(:id).of_type(:integer) }
    it { is_expected.to have_db_column(:enrollment_id).of_type(:integer) }
    it { is_expected.to have_db_column(:course_id).of_type(:integer) }
    it { is_expected.to have_db_column(:ranking).of_type(:integer) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime) }
  end

  describe 'ranking attribute' do
    it 'allows ranking to be nil' do
      preference = build(:course_preference, ranking: nil)
      expect(preference).to be_valid
      expect(preference.ranking).to be_nil
    end

    it 'allows ranking to be set to an integer' do
      preference = build(:course_preference, ranking: 5)
      expect(preference).to be_valid
      expect(preference.ranking).to eq(5)
    end

    it 'allows ranking to be updated' do
      preference = create(:course_preference, ranking: 3)
      preference.update(ranking: 7)
      expect(preference.reload.ranking).to eq(7)
    end

    context 'with valid ranking values' do
      [1, 5, 10, 12, nil].each do |value|
        it "accepts ranking value of #{value.inspect}" do
          preference = build(:course_preference, ranking: value)
          expect(preference).to be_valid
        end
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      preference = build(:course_preference)
      expect(preference).to be_valid
    end

    it 'creates a persisted preference' do
      preference = create(:course_preference)
      expect(preference).to be_persisted
      expect(preference).to be_valid
    end

    it 'creates preference with enrollment and course' do
      preference = create(:course_preference)
      expect(preference.enrollment).to be_present
      expect(preference.course).to be_present
    end

    it 'creates preference with a ranking' do
      preference = create(:course_preference)
      expect(preference.ranking).to be_between(1, 10)
    end

    it 'allows creating preference without ranking' do
      preference = create(:course_preference, ranking: nil)
      expect(preference.ranking).to be_nil
      expect(preference).to be_valid
    end

    it 'allows creating preference with specific ranking' do
      preference = create(:course_preference, ranking: 8)
      expect(preference.ranking).to eq(8)
    end
  end

  describe 'ransackable methods' do
    describe '.ransackable_associations' do
      it 'returns array of ransackable associations' do
        expect(CoursePreference.ransackable_associations).to match_array(['course', 'enrollment'])
      end

      it 'accepts auth_object parameter' do
        expect { CoursePreference.ransackable_associations(nil) }.not_to raise_error
        expect { CoursePreference.ransackable_associations(double) }.not_to raise_error
      end
    end

    describe '.ransackable_attributes' do
      it 'returns array of ransackable attributes' do
        expected_attributes = ['course_id', 'created_at', 'enrollment_id', 'id', 'ranking', 'updated_at']
        expect(CoursePreference.ransackable_attributes).to match_array(expected_attributes)
      end

      it 'accepts auth_object parameter' do
        expect { CoursePreference.ransackable_attributes(nil) }.not_to raise_error
        expect { CoursePreference.ransackable_attributes(double) }.not_to raise_error
      end
    end
  end

  describe 'integration with enrollment and course' do
    let!(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year) }
    let!(:session) { create(:camp_occurrence, camp_configuration: camp_config, active: true) }
    let!(:course) { create(:course, camp_occurrence: session) }
    let!(:enrollment) { create(:enrollment, campyear: camp_config.camp_year) }

    it 'is destroyed when enrollment is destroyed' do
      # Clear any existing preferences created by the factory
      enrollment.course_preferences.destroy_all
      enrollment.reload
      preference = create(:course_preference, enrollment: enrollment, course: course)
      preference_id = preference.id

      expect {
        enrollment.destroy
      }.to change { CoursePreference.count }.by(-1)

      expect(CoursePreference.find_by(id: preference_id)).to be_nil
    end

    it 'is destroyed when course is destroyed' do
      # Clear any existing preferences created by the factory
      enrollment.course_preferences.destroy_all
      enrollment.reload
      preference = create(:course_preference, enrollment: enrollment, course: course)
      preference_id = preference.id

      expect {
        course.destroy
      }.to change { CoursePreference.count }.by(-1)

      expect(CoursePreference.find_by(id: preference_id)).to be_nil
    end

    it 'can access enrollment through association' do
      preference = create(:course_preference, enrollment: enrollment, course: course)
      expect(preference.enrollment).to eq(enrollment)
    end

    it 'can access course through association' do
      preference = create(:course_preference, enrollment: enrollment, course: course)
      expect(preference.course).to eq(course)
    end

    it 'can access course camp_occurrence through course association' do
      preference = create(:course_preference, enrollment: enrollment, course: course)
      expect(preference.course.camp_occurrence).to eq(session)
    end
  end

  describe 'scopes and queries' do
    let!(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year) }
    let!(:session1) { create(:camp_occurrence, camp_configuration: camp_config, active: true, description: 'Session 1') }
    let!(:session2) { create(:camp_occurrence, camp_configuration: camp_config, active: true, description: 'Session 2') }
    let!(:course1) { create(:course, camp_occurrence: session1) }
    let!(:course2) { create(:course, camp_occurrence: session2) }
    let!(:enrollment1) { create(:enrollment, campyear: camp_config.camp_year) }
    let!(:enrollment2) { create(:enrollment, campyear: camp_config.camp_year) }

    before do
      # Clear any existing preferences created by the factory
      enrollment1.course_preferences.destroy_all
      enrollment2.course_preferences.destroy_all
      enrollment1.reload
      enrollment2.reload
    end

    it 'can find preferences by enrollment' do
      preference1 = create(:course_preference, enrollment: enrollment1, course: course1, ranking: 1)
      preference2 = create(:course_preference, enrollment: enrollment1, course: course2, ranking: 2)
      create(:course_preference, enrollment: enrollment2, course: course1, ranking: 1)

      enrollment1.reload
      expect(enrollment1.course_preferences).to include(preference1, preference2)
      expect(enrollment1.course_preferences.count).to eq(2)
    end

    it 'can find preferences by course' do
      preference1 = create(:course_preference, enrollment: enrollment1, course: course1, ranking: 1)
      preference2 = create(:course_preference, enrollment: enrollment2, course: course1, ranking: 1)
      create(:course_preference, enrollment: enrollment1, course: course2, ranking: 1)

      expect(course1.course_preferences).to include(preference1, preference2)
      expect(course1.course_preferences.count).to eq(2)
    end

    it 'can filter preferences by ranking' do
      create(:course_preference, enrollment: enrollment1, course: course1, ranking: 1)
      create(:course_preference, enrollment: enrollment1, course: course2, ranking: 2)
      create(:course_preference, enrollment: enrollment1, course: create(:course, camp_occurrence: session1), ranking: nil)

      ranked_preferences = CoursePreference.where.not(ranking: nil)
      expect(ranked_preferences.count).to eq(2)

      unranked_preferences = CoursePreference.where(ranking: nil)
      expect(unranked_preferences.count).to eq(1)
    end

    it 'can order preferences by ranking' do
      pref3 = create(:course_preference, enrollment: enrollment1, course: course1, ranking: 3)
      pref1 = create(:course_preference, enrollment: enrollment1, course: course2, ranking: 1)
      pref2 = create(:course_preference, enrollment: enrollment1, course: create(:course, camp_occurrence: session1), ranking: 2)

      ordered = enrollment1.course_preferences.order(:ranking).to_a
      expect(ordered.map(&:id)).to match_array([pref1.id, pref2.id, pref3.id])
      expect(ordered.map(&:ranking)).to eq([1, 2, 3])
    end
  end

  describe 'multiple preferences per enrollment' do
    let!(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year) }
    let!(:session) { create(:camp_occurrence, camp_configuration: camp_config, active: true) }
    let!(:enrollment) { create(:enrollment, campyear: camp_config.camp_year) }

    before do
      # Clear any existing preferences created by the factory
      enrollment.course_preferences.destroy_all
      enrollment.reload
    end

    it 'allows multiple preferences for the same enrollment' do
      course1 = create(:course, camp_occurrence: session)
      course2 = create(:course, camp_occurrence: session)
      course3 = create(:course, camp_occurrence: session)

      preference1 = create(:course_preference, enrollment: enrollment, course: course1, ranking: 1)
      preference2 = create(:course_preference, enrollment: enrollment, course: course2, ranking: 2)
      preference3 = create(:course_preference, enrollment: enrollment, course: course3, ranking: 3)

      enrollment.reload
      expect(enrollment.course_preferences.count).to eq(3)
      expect(enrollment.course_preferences).to include(preference1, preference2, preference3)
    end

    it 'allows same ranking for different courses' do
      course1 = create(:course, camp_occurrence: session)
      course2 = create(:course, camp_occurrence: session)

      preference1 = create(:course_preference, enrollment: enrollment, course: course1, ranking: 1)
      preference2 = create(:course_preference, enrollment: enrollment, course: course2, ranking: 1)

      expect(preference1).to be_valid
      expect(preference2).to be_valid
      expect(enrollment.course_preferences.where(ranking: 1).count).to eq(2)
    end
  end

  describe 'edge cases' do
    let!(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year) }
    let!(:session) { create(:camp_occurrence, camp_configuration: camp_config, active: true) }
    let!(:course) { create(:course, camp_occurrence: session) }
    let!(:enrollment) { create(:enrollment, campyear: camp_config.camp_year) }

    before do
      # Clear any existing preferences created by the factory
      enrollment.course_preferences.destroy_all
    end

    it 'handles very large ranking values' do
      preference = build(:course_preference, enrollment: enrollment, course: course, ranking: 999)
      expect(preference).to be_valid
    end

    it 'handles negative ranking values' do
      preference = build(:course_preference, enrollment: enrollment, course: course, ranking: -1)
      # Note: The model doesn't validate ranking range, so this should be valid
      expect(preference).to be_valid
    end

    it 'handles zero ranking value' do
      preference = build(:course_preference, enrollment: enrollment, course: course, ranking: 0)
      expect(preference).to be_valid
    end

    it 'can update ranking from nil to a value' do
      preference = create(:course_preference, enrollment: enrollment, course: course, ranking: nil)
      preference.update(ranking: 5)
      expect(preference.reload.ranking).to eq(5)
    end

    it 'can update ranking from a value to nil' do
      preference = create(:course_preference, enrollment: enrollment, course: course, ranking: 5)
      preference.update(ranking: nil)
      expect(preference.reload.ranking).to be_nil
    end
  end

  it_behaves_like 'a model with timestamps'
end
