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
# Indexes
#
#  index_recuploads_on_recommendation_id_unique  (recommendation_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (recommendation_id => recommendations.id)
#
class Recupload < ApplicationRecord
  include AdminCommentable

  belongs_to :recommendation
  # A letter is written under its recommendation's row lock — the same lock RecuploadsController
  # and Recommendation#issue_upload_token! take — so letters, public uploads and admin resends
  # for one recommendation always serialise, whichever controller or console they come from.
  before_save :lock_recommendation, if: :will_save_change_to_recommendation_id?
  after_create :update_enrollment_status
  # The emailed upload link is single-use: once a letter is in, the token is cleared. Fires on
  # create and on any (re)assignment of the recommendation, so the owner can never keep a live
  # link while holding a letter.
  after_save :invalidate_upload_token, if: :saved_change_to_recommendation_id?

  # validates :letter, length: { minimum: 50 }
  # One letter per recommendation (backed by a unique index; RecuploadsController serialises the
  # public submission under a row lock so the emailed link really is single-use).
  validates :recommendation_id, uniqueness: { message: 'already has a letter' }
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
      enrollment.transition_application_status!('application complete')
    end
  end

  def lock_recommendation
    recommendation&.lock!
  end

  def invalidate_upload_token
    recommendation.invalidate_upload_token!
  end
end
