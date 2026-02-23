# frozen_string_literal: true

# Records each time we send a user to the Nelnet payment processor (redirect with signed URL).
# When the callback hits payment_receipt, we link the received Payment to the matching
# PaymentRequest so we can see which requests were fulfilled and which were never received.
#
# Query unmatched (sent but no receipt): PaymentRequest.where(payment_id: nil)
class PaymentRequest < ApplicationRecord
  belongs_to :user
  belongs_to :payment, optional: true

  validates :order_number, presence: true
  validates :amount_cents, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :request_timestamp, presence: true

  scope :unmatched, -> { where(payment_id: nil) }
  scope :for_camp_year, ->(year) { where(camp_year: year) }

  def self.ransackable_associations(_auth_object = nil)
    %w[payment user]
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[amount_cents camp_year created_at id order_number payment_id request_timestamp updated_at user_id]
  end
end
