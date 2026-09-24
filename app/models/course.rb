# frozen_string_literal: true

# == Schema Information
#
# Table name: courses
#
#  id                 :bigint           not null, primary key
#  camp_occurrence_id :bigint           not null
#  title              :string(255)
#  available_spaces   :integer
#  status             :string(255)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  faculty_uniqname   :string(255)
#  faculty_name       :string(255)
#
# Indexes
#
#  index_courses_on_camp_occurrence_id  (camp_occurrence_id)
#
# Foreign Keys
#
#  fk_rails_...  (camp_occurrence_id => camp_occurrences.id)
#
class Course < ApplicationRecord
  include AdminCommentable

  belongs_to :camp_occurrence
  has_many :course_preferences, dependent: :destroy
  has_many :course_assignments, dependent: :destroy
  has_many :enrolled_users, through: :course_preferences, source: :enrollment

  validates :faculty_uniqname, format: { with: /\A[\w.-]+\z/,
    message: "usernames or uniqnames only - do not include domain" }
  validates :title, presence: true
  validates :available_spaces, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :is_open, -> { where(status: "open") }
  scope :open, -> { where(status: "open") }
  scope :current_camp, -> { where(camp_occurrence_id: CampOccurrence.active) }

  # Adds confirmed/wait-list assignment counts as select columns so list pages and CSV exports
  # get remaining_spaces / wait_list_count without two queries per row.
  scope :with_seat_counts, lambda {
    select(
      'courses.*',
      '(SELECT COUNT(*) FROM course_assignments ca WHERE ca.course_id = courses.id AND ca.wait_list = FALSE) AS confirmed_assignments_count',
      '(SELECT COUNT(*) FROM course_assignments ca WHERE ca.course_id = courses.id AND ca.wait_list = TRUE) AS wait_list_count'
    )
  }

  def display_name
    "#{self.title} - #{self.camp_occurrence.description}" # or whatever column you want
  end

  def remaining_spaces
    base_spaces = self[:available_spaces]
    return 0 if base_spaces.nil?

    [base_spaces - confirmed_assignments_count, 0].max
  end

  def confirmed_assignments_count
    has_attribute?(:confirmed_assignments_count) ? self[:confirmed_assignments_count].to_i : course_assignments.confirmed.count
  end

  def wait_list_count
    has_attribute?(:wait_list_count) ? self[:wait_list_count].to_i : course_assignments.where(wait_list: true).count
  end
end
