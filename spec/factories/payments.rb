# == Schema Information
#
# Table name: payments
#
#  id                 :bigint           not null, primary key
#  transaction_type   :string(255)
#  transaction_status :string(255)
#  transaction_id     :string(255)
#  total_amount       :string(255)
#  transaction_date   :string(255)
#  account_type       :string(255)
#  result_code        :string(255)
#  result_message     :string(255)
#  user_account       :string(255)
#  payer_identity     :string(255)
#  timestamp          :string(255)
#  transaction_hash   :string(255)
#  user_id            :bigint           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  camp_year          :integer
#
FactoryBot.define do
  factory :payment do
    transaction_type { "MyString" }
    transaction_status { "MyString" }
    transaction_id { "MyString" }
    total_amount { "MyString" }
    transaction_date { "MyString" }
    account_type { "MyString" }
    result_code { "MyString" }
    result_message { "MyString" }
    user_accoun { "MyString" }
    payer_identity { "MyString" }
    timestamp { "MyString" }
    transaction_hash { "MyString" }
    user { nil }
  end
end
