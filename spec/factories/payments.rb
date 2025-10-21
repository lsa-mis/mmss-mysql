# frozen_string_literal: true

FactoryBot.define do
  factory :payment do
    association :user

    total_amount { rand(10000..50000) }
    transaction_type { '1' }
    transaction_status { '1' }
    sequence(:transaction_id) { |n| "TXN#{Time.current.to_i}#{n}" }
    transaction_date { DateTime.current.strftime('%Y%m%d%H%M') }
    account_type { ['credit_card', 'debit_card', 'bank_transfer'].sample }
    result_code { '0' }
    result_message { 'Success' }
    user_account { "****#{rand(1000..9999)}" }
    timestamp { DateTime.current }
    camp_year { Date.current.year }

    trait :failed do
      transaction_status { '0' }
      result_code { '1' }
      result_message { 'Payment failed' }
    end

    trait :pending do
      transaction_status { '2' }
      result_message { 'Pending approval' }
    end

    trait :credit_card do
      account_type { 'credit_card' }
    end

    trait :bank_transfer do
      account_type { 'bank_transfer' }
    end
  end
end
