# frozen_string_literal: true

# == Schema Information
#
# Table name: recuploads
#
#  id                :bigint           not null, primary key
#  letter            :text(65535)
#  authorname        :string(255)      not null
#  studentname       :string(255)      not null
#  recommendation_id :bigint           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class Recupload < ApplicationRecord
  belongs_to :recommendation
  after_create :update_enrollment_status

  # validates :letter, length: { minimum: 50 }
  validates :authorname, presence: true
  validates :studentname, presence: true

  has_one_attached :recletter

  validate :validate_recletter

  private

  def validate_recletter
    if recletter.attached?
      errors.add(:recletter, 'is too big - file size cannot exceed 20Mbyte') if recletter.blob.byte_size > 20.megabytes

      acceptable_types = ['image/png', 'image/jpeg', 'application/pdf']
      unless acceptable_types.include?(recletter.content_type)
        errors.add(:recletter, 'must be file type PDF, JPEG or PNG')
      end
    elsif letter.blank?
      errors.add(:recletter, 'must be attached or letter text must be provided')
    end
  end

  def update_enrollment_status
    enrollment = Recommendation.find(recommendation_id).enrollment
    if !enrollment.application_fee_required || Payment.where(user_id: enrollment.user_id).status1_current_camp_payments.exists?
      enrollment.update!(application_status: 'application complete', application_status_updated_on: Date.today)
    end
  end
end
