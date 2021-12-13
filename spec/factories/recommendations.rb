# == Schema Information
#
# Table name: recommendations
#
#  id                       :bigint           not null, primary key
#  enrollment_id            :bigint           not null
#  email                    :string(255)      not null
#  lastname                 :string(255)      not null
#  firstname                :string(255)      not null
#  organization             :string(255)
#  address1                 :string(255)
#  address2                 :string(255)
#  city                     :string(255)
#  state                    :string(255)
#  state_non_us             :string(255)
#  postalcode               :string(255)
#  country                  :string(255)
#  phone_number             :string(255)
#  best_contact_time        :string(255)
#  submitted_recommendation :string(255)
#  date_submitted           :datetime
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#
FactoryBot.define do
  factory :recommendation do
    enrollment { nil }
    email { "MyString" }
    lastname { "MyString" }
    firstname { "MyString" }
    organization { "MyString" }
    address1 { "MyString" }
    address2 { "MyString" }
    city { "MyString" }
    state { "MyString" }
    state_non_us { "MyString" }
    postalcode { "MyString" }
    country { "MyString" }
    phone_number { "MyString" }
    best_contact_time { "MyString" }
    submitted_recommendation { "MyString" }
    date_submitted { "2019-10-08 11:25:04" }
  end
end
