# == Schema Information
#
# Table name: payments
#
#  id                 :bigint           not null, primary key
#  transaction_type   :string
#  transaction_status :string
#  transaction_id     :string
#  total_amount       :string
#  transaction_date   :string
#  account_type       :string
#  result_code        :string
#  result_message     :string
#  user_account       :string
#  payer_identity     :string
#  timestamp          :string
#  transaction_hash   :string
#  user_id            :bigint           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  camp_year          :integer
#
class Payment < ApplicationRecord
  include ApplicantState

  after_commit :set_status, if: :persisted?

  validates :transaction_id, presence: true, uniqueness: true
  validates :total_amount, presence: true
  validates :transaction_date, presence: true

  belongs_to :user

  scope :current_camp_payments, -> { where('camp_year = ? ', CampConfiguration.active_camp_year) }

  private

  def set_status
    return unless self.transaction_status == '1'

    @current_enrollment = self.user.enrollments.current_camp_year_applications.last
    if self.user.payments.current_camp_payments.where(transaction_status: 1).count == 1
      RegistrationMailer.app_complete_email(self.user).deliver_now
      @current_enrollment.update!(application_status: "submitted")
      if @current_enrollment.recommendation.present?
        if @current_enrollment.recommendation.recupload.present? 
          @current_enrollment.update!(application_status: "application complete")
        end
      end
    else 
      if balance_due == 0 && @current_enrollment.student_packet.attached?
        @current_enrollment.update!(application_status: "enrolled")
      end
    end
  end
end
