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

  def self.ransackable_associations(auth_object = nil)
    ["course", "enrollment"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["course_id", "created_at", "enrollment_id", "id", "ranking", "updated_at"]
  end

  private

  def ranking_upper_bound
    return MAX_RANKING unless enrollment_id && course

    count = CoursePreference.where(enrollment_id: enrollment_id)
      .joins(:course)
      .where(courses: { camp_occurrence_id: course.camp_occurrence_id })
      .count
    [[count, MAX_RANKING].max, 99].min
  end

  def ranking_within_session_upper_bound
    return if ranking.blank? || course.blank?
    return if ranking <= ranking_upper_bound

    errors.add(:ranking, "must be between 1 and #{ranking_upper_bound} for this session")
  end

  def ranking_unique_within_enrollment_session
    return if ranking.blank? || course.blank?

    scope = CoursePreference.joins(:course)
      .where(enrollment_id: enrollment_id, ranking: ranking)
      .where(courses: { camp_occurrence_id: course.camp_occurrence_id })
    scope = scope.where.not(id: id) if persisted?

    errors.add(:ranking, 'must be unique within each camp session') if scope.exists?
  end
end
