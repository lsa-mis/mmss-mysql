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
class SessionActivity < ApplicationRecord
  belongs_to :enrollment
  belongs_to :camp_occurrence

  def self.ransackable_associations(auth_object = nil)
    ["camp_occurrence", "enrollment"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["camp_occurrence_id", "created_at", "enrollment_id", "id", "updated_at"]
  end
end
