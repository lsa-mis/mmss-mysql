# frozen_string_literal: true

# == Schema Information
#
# Table name: campnotes
#
#  id         :bigint           not null, primary key
#  note       :string(255)
#  opendate   :datetime
#  closedate  :datetime
#  notetype   :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Campnote < ApplicationRecord
  validates :note, :notetype, presence: true

  validates :opendate, :closedate, presence: true, availability: true
  validate :end_date_after_start_date

  # Notes whose open/close window covers now. Rows with a NULL date never match (same as the
  # previous Ruby `present?` checks).
  scope :currently_open, lambda {
    now = Time.current
    where.not(opendate: nil).where.not(closedate: nil).where('opendate <= ? AND closedate >= ?', now, now)
  }

  private

  def end_date_after_start_date
    return if closedate.blank? || opendate.blank?

    if closedate < opendate
      errors.add(:closedate, "must be after the start date")
    end
  end

  def self.ransackable_attributes(auth_object = nil)
    ["closedate", "created_at", "id", "note", "notetype", "opendate", "updated_at"]
  end

end
