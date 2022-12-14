# == Schema Information
#
# Table name: genders
#
#  id          :bigint           not null, primary key
#  name        :string(255)      not null
#  description :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
FactoryBot.define do
  factory :gender do
    name { "MyString" }
    description { "MyString" }
  end
end
