# frozen_string_literal: true

# == Schema Information
#
# Table name: enrollment_activities
#
#  id            :bigint           not null, primary key
#  enrollment_id :bigint           not null
#  activity_id   :bigint           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class EnrollmentActivity < ApplicationRecord
  belongs_to :enrollment
  belongs_to :activity

  validates_presence_of :enrollment
  validates_presence_of :activity

  def self.ransackable_associations(auth_object = nil)
    ["activity", "enrollment"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["activity_id", "created_at", "enrollment_id", "id", "updated_at"]
  end
end
