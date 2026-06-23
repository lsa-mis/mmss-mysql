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
class CoursePreference < ApplicationRecord
  MAX_RANKING = 12

  belongs_to :enrollment
  belongs_to :course

  validates :course_id, uniqueness: { scope: :enrollment_id }
  validates :ranking,
            numericality: {
              only_integer: true,
              allow_nil: true,
              greater_than_or_equal_to: 1
            }
  validate :ranking_within_session_upper_bound
  validate :ranking_unique_within_enrollment_session

  def self.ransackable_associations(_auth_object = nil)
    ["course", "enrollment"]
  end

  def self.ransackable_attributes(_auth_object = nil)
    ["course_id", "created_at", "enrollment_id", "id", "ranking", "updated_at"]
  end

  private

  def ranking_upper_bound
    return MAX_RANKING unless course && (enrollment || enrollment_id)

    [session_course_preferences.size, MAX_RANKING].min
  end

  def ranking_within_session_upper_bound
    return if ranking.blank? || course.blank?
    return if ranking <= ranking_upper_bound

    errors.add(:ranking, "must be between 1 and #{ranking_upper_bound} for this session")
  end

  def ranking_unique_within_enrollment_session
    return if ranking.blank? || course.blank?

    duplicate_rank = session_course_preferences.any? do |preference|
      !same_record?(preference) && preference.ranking == ranking
    end

    errors.add(:ranking, 'must be unique within each camp session') if duplicate_rank
  end

  def session_course_preferences
    preferences = persisted_session_course_preferences + in_memory_course_preferences + [self]

    preferences.compact
      .reject(&:marked_for_destruction?)
      .select { |preference| preference.course&.camp_occurrence_id == course.camp_occurrence_id }
      .uniq { |preference| preference.id || preference.object_id }
  end

  def persisted_session_course_preferences
    return [] unless enrollment_id

    CoursePreference.includes(:course)
      .joins(:course)
      .where(enrollment_id: enrollment_id)
      .where(courses: { camp_occurrence_id: course.camp_occurrence_id })
      .to_a
  end

  def in_memory_course_preferences
    return [] unless enrollment

    enrollment.association(:course_preferences).target
  end

  def same_record?(preference)
    preference.equal?(self) || (id.present? && preference.id == id)
  end
end
