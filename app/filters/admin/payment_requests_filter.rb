# frozen_string_literal: true

class Admin::PaymentRequestsFilter < Admin::Filter
  select :user_id, label: 'User', collection: -> { User.order(:email).pluck(:email, :id) }
  text :order_number
  select :camp_year, collection: -> { PaymentRequest.where.not(camp_year: nil).distinct.order(camp_year: :desc).pluck(:camp_year) }
  select :payment_id, label: 'Matched payment', collection: lambda {
    Payment.order(created_at: :desc).limit(500).map do |payment|
      ["#{payment.transaction_id} (#{payment.created_at.strftime('%Y-%m-%d %H:%M')})", payment.id]
    end
  }
  date_range :created_at
end
