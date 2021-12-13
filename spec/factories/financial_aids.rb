# == Schema Information
#
# Table name: financial_aids
#
#  id                :bigint           not null, primary key
#  enrollment_id     :bigint           not null
#  amount_cents      :integer          default(0)
#  source            :string(255)
#  note              :text(65535)
#  status            :string(255)      default("pending")
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  payments_deadline :date
#
FactoryBot.define do
  factory :financial_aid do
    enrollment { nil }
    amount_cents { 1 }
    source { "MyString" }
    awarded { false }
    note { "MyText" }
    status { "MyString" }
  end
end
