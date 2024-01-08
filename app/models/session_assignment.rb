# == Schema Information
#
# Table name: session_assignments
#
#  id                 :bigint           not null, primary key
#  enrollment_id      :bigint           not null
#  camp_occurrence_id :bigint           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  offer_status       :string(255)
#
class SessionAssignment < ApplicationRecord
  belongs_to :enrollment
  belongs_to :camp_occurrence

  scope :current_year_session_assignments, -> { where(enrollment_id: Enrollment.current_camp_year_applications) }
  scope :accepted, -> { current_year_session_assignments.where(offer_status: 'accepted') }

  def self.ransackable_associations(auth_object = nil)
    ["camp_occurrence", "enrollment"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["camp_occurrence_id", "created_at", "enrollment_id", "id", "offer_status", "updated_at"]
  end
end
