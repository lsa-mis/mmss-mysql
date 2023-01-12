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
class Course < ApplicationRecord
  belongs_to :camp_occurrence
  has_many :course_preferences
  has_many :course_assignments
  has_many :enrolled_users, through: :course_preferences, source: :enrollment

  validates :faculty_uniqname, format: { with: /\A[\w.-]+\z/,
    message: "usernames or uniqnames only - do not include domain" }

  scope :is_open, -> { where(status: "open") }
  scope :current_camp, -> { where(camp_occurrence_id: CampOccurrence.active) }

  def display_name
    "#{self.title} - #{self.camp_occurrence.description}" # or whatever column you want
  end

end
