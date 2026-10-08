# frozen_string_literal: true

# == Schema Information
#
# Table name: recommendations
#
#  id                       :bigint           not null, primary key
#  enrollment_id            :bigint           not null
#  email                    :string(255)      not null
#  lastname                 :string(255)      not null
#  firstname                :string(255)      not null
#  organization             :string(255)
#  address1                 :string(255)
#  address2                 :string(255)
#  city                     :string(255)
#  state                    :string(255)
#  state_non_us             :string(255)
#  postalcode               :string(255)
#  country                  :string(255)
#  phone_number             :string(255)
#  best_contact_time        :string(255)
#  submitted_recommendation :string(255)
#  date_submitted           :datetime
#  upload_token             :string(255)
#  upload_token_expires_at  :datetime
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#
# Indexes
#
#  index_recommendations_on_enrollment_id  (enrollment_id)
#  index_recommendations_on_upload_token   (upload_token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (enrollment_id => enrollments.id)
#
class Recommendation < ApplicationRecord
  include AdminCommentable

  # The recommender uploads the letter through an emailed link that carries `upload_token`
  # (no login). The token is random (has_secure_token), expires UPLOAD_TOKEN_TTL after it is
  # issued and is cleared once a letter is received, so a link can be used at most once.
  # Admins issue a fresh link with #issue_upload_token! ("Resend request").
  UPLOAD_TOKEN_TTL = 60.days

  belongs_to :enrollment
  has_one :recupload, dependent: :destroy

  has_secure_token :upload_token
  before_create :set_upload_token_expiry

  validates :email, presence: true, length: {maximum: 255},
                    format: {with: URI::MailTo::EMAIL_REGEXP, message: "only allows valid emails"}
  validates :firstname, presence: true
  validates :lastname, presence: true
  validates :organization, presence: true

  # Resolves an emailed upload link. A blank token never matches (recommendations whose letter
  # has been received have a NULL token).
  def self.find_by_upload_token(token)
    token = token.to_s
    return nil if token.blank?

    find_by(upload_token: token)
  end

  # Raised by #issue_upload_token! when a letter has (just) been received: no link may be issued.
  class LetterAlreadyReceived < StandardError; end

  # A new link for the recommender; any previously emailed link stops working. Runs under the
  # recommendation's row lock (the same lock RecuploadsController#create takes) and re-checks for
  # a letter after acquiring it, so a concurrent upload can never have its cleared token restored.
  # Writes the columns directly: issuing a link must not depend on legacy rows passing today's
  # validations.
  #
  # With `only_if_missing: true` (the post-deploy sweep) the token is issued only when the row
  # still has none once the lock is held, so a link an admin has just emailed is never rotated.
  # Returns true when a token was issued, false when skipped.
  def issue_upload_token!(only_if_missing: false)
    raise ActiveRecord::RecordNotSaved.new('cannot issue an upload token for an unsaved recommendation', self) unless persisted?

    outcome = transaction do
      lock!
      next :letter_received if recupload.present?
      next :skipped if only_if_missing && upload_token.present?

      update_columns(upload_token: self.class.generate_unique_secure_token, upload_token_expires_at: UPLOAD_TOKEN_TTL.from_now,
                     updated_at: Time.current)
      :issued
    end
    raise LetterAlreadyReceived, "recommendation #{id} already has a letter" if outcome == :letter_received

    outcome == :issued
  end

  # Called once a letter is received: the link is dead from then on.
  def invalidate_upload_token!
    update_columns(upload_token: nil, upload_token_expires_at: nil)
  end

  def upload_token_expired?
    upload_token_expires_at.nil? || upload_token_expires_at.past?
  end

  # True while the emailed link can still be used to upload a letter.
  def upload_link_active?
    upload_token.present? && !upload_token_expired? && recupload.nil?
  end

  def full_name
    "#{firstname} #{lastname}"
  end

  def display_name
    "#{lastname}, #{firstname}"
  end

  def applicant_name
    self.enrollment.user.applicant_detail.full_name
  end

  private

  def set_upload_token_expiry
    self.upload_token_expires_at ||= UPLOAD_TOKEN_TTL.from_now
  end
end
