# == Schema Information
#
# Table name: courses
#
#  id                 :bigint           not null, primary key
#  camp_occurrence_id :bigint           not null
#  title              :string
#  available_spaces   :integer
#  status             :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
class Course < ApplicationRecord
  belongs_to :camp_occurrence
  has_many :course_preferences
  has_many :course_assignments
  has_many :enrolled_users, through: :course_preferences, source: :enrollment


  scope :is_open, -> { where(status: "open") }
  scope :current_camp, -> { where(camp_occurrence_id: CampOccurrence.active) }

  scope :courses_filter, -> do
    Course.table_exists? ? Course.where(camp_occurrence_id: CampOccurrence.active).order(camp_occurrence_id: :asc, title: :asc) : {}
  end

  scope :course_preferences_filter, -> do
    Course.table_exists? ? Course.where(camp_occurrence_id: CampOccurrence.active).order(camp_occurrence_id: :asc, title: :asc) : {}
  end
  
  def display_name
    "#{self.title} - #{self.camp_occurrence.description}" # or whatever column you want
  end
end
