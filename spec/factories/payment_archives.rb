# == Schema Information
#
# Table name: payment_archives
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
#  camp_year          :integer
#  user_email         :string(255)
#  first_name         :string(255)
#  last_name          :string(255)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
FactoryBot.define do
  factory :payment_archive do
    
  end
end
