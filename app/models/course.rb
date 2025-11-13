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

  def display_name
    "#{self.title} - #{self.camp_occurrence.description}" # or whatever column you want
  end

  def remaining_spaces
    base_spaces = self[:available_spaces]
    return 0 if base_spaces.nil?

    [base_spaces - course_assignments.confirmed.count, 0].max
  end

  def self.ransackable_associations(_auth_object = nil)
    ["camp_occurrence", "course_assignments", "course_preferences", "enrolled_users"]
  end

  def self.ransackable_attributes(_auth_object = nil)
    ["available_spaces", "camp_occurrence_id", "created_at", "faculty_name", "faculty_uniqname", "id", "status", "title", "updated_at"]
  end
end
