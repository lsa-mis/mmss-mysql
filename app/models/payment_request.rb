# frozen_string_literal: true

# Records each time we send a user to the Nelnet payment processor (redirect with signed URL).
# When the callback hits payment_receipt, we link the received Payment to the matching
# PaymentRequest so we can see which requests were fulfilled and which were never received.
#
# Query unmatched (sent but no receipt): PaymentRequest.where(payment_id: nil)

# == Schema Information
#
# Table name: payment_requests
#
#  id                                                         :bigint           not null, primary key
#  user_id                                                    :bigint           not null
#  order_number(Sent to Nelnet as orderNumber (user_account)) :string(255)      not null
#  amount_cents(Amount sent in request (cents))               :integer          not null
#  camp_year                                                  :integer
#  request_timestamp(Epoch timestamp sent in URL to Nelnet)   :bigint           not null
#  payment_id(Set when receipt received)                      :bigint
#  created_at                                                 :datetime         not null
#  updated_at                                                 :datetime         not null
#
# Indexes
#
#  index_payment_requests_on_payment_id                (payment_id)
#  index_payment_requests_on_user_id                   (user_id)
#  index_payment_requests_on_user_id_and_order_number  (user_id,order_number)
#
# Foreign Keys
#
#  fk_rails_...  (payment_id => payments.id)
#  fk_rails_...  (user_id => users.id)
#
class PaymentRequest < ApplicationRecord
  belongs_to :user
  belongs_to :payment, optional: true

  validates :order_number, presence: true
  validates :amount_cents, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :request_timestamp, presence: true

  scope :unmatched, -> { where(payment_id: nil) }
  scope :for_camp_year, ->(year) { where(camp_year: year) }

  # Epoch milliseconds sent to Nelnet, as a local time (nil when missing).
  def requested_at
    Time.zone.at(request_timestamp / 1000) if request_timestamp.present?
  end
end
