# frozen_string_literal: true

# == Schema Information
#
# Table name: nelnet_callback_logs
#
#  id                                                     :bigint           not null, primary key
#  transaction_id(Nelnet transactionId from callback)     :string(255)
#  order_number(orderNumber from callback (user_account)) :string(255)
#  transaction_status                                     :string(255)
#  transaction_total_amount                               :string(255)
#  raw_params(Full request params as JSON)                :text(65535)
#  created_at                                             :datetime         not null
#  updated_at                                             :datetime         not null
#
FactoryBot.define do
  factory :nelnet_callback_log do
    sequence(:transaction_id) { |n| "NLN#{100_000 + n}" }
    sequence(:order_number) { |n| "user#{n}-#{n}" }
    transaction_status { '1' }
    transaction_total_amount { '25000' }
    raw_params { { 'transactionId' => transaction_id, 'orderNumber' => order_number, 'transactionStatus' => transaction_status }.to_json }
  end
end
