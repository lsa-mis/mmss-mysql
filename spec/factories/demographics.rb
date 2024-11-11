# == Schema Information
#
# Table name: demographics
#
#  id          :bigint           not null, primary key
#  name        :string(255)      not null
#  description :string(255)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
FactoryBot.define do
  factory :demographic do
    sequence(:name) { |n| "Demographic #{n}" }
    sequence(:description) { |n| "Description for demographic #{n}" }
  end
end
