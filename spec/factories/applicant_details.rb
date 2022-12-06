# == Schema Information
#
# Table name: applicant_details
#
#  id                 :bigint           not null, primary key
#  user_id            :bigint           not null
#  firstname          :string           not null
#  middlename         :string
#  lastname           :string           not null
#  gender             :string
#  us_citizen         :boolean          default(FALSE), not null
#  demographic        :string
#  birthdate          :date             not null
#  diet_restrictions  :string
#  shirt_size         :string
#  address1           :string           not null
#  address2           :string
#  city               :string           not null
#  state              :string           not null
#  state_non_us       :string
#  postalcode         :string           not null
#  country            :string           not null
#  phone              :string           not null
#  parentname         :string           not null
#  parentaddress1     :string
#  parentaddress2     :string
#  parentcity         :string
#  parentstate        :string
#  parentstate_non_us :string
#  parentzip          :string
#  parentcountry      :string
#  parentphone        :string           not null
#  parentworkphone    :string
#  parentemail        :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
FactoryBot.define do
  factory :applicant_detail do
    association :user
    firstname { Faker::Name.first_name }
    middlename { Faker::Name.middle_name }
    lastname { Faker::Name.last_name }
    gender { Faker::Gender.binary_type }
    # us_citizen { Faker::Boolean.boolean }
    demographic { Faker::Demographic.race }
    birthdate { Faker::Date.birthday(min_age: 15, max_age: 18) }
    diet_restrictions { "peanuts" }
    shirt_size { "Large" }
    address1 { Faker::Address.street_address }
    address2 { Faker::Address.secondary_address }
    city { Faker::Address.city }
    state { Faker::Address.state_abbr }
    # state_non_us { "MyString" }
    postalcode { Faker::Address.zip_code }
    country { "US" }
    # phone { Faker::PhoneNumber.cell_phone }
    phone { "123-333-5555" }
    parentname { Faker::Name.name }
    parentaddress1 { Faker::Address.street_address }
    parentaddress2 { Faker::Address.secondary_address }
    parentcity { Faker::Address.city }
    parentstate { Faker::Address.state_abbr }
    # parentstate_non_us { "MyString" }
    parentzip { Faker::Address.zip_code  }
    parentcountry { "US" }
    parentphone { "123-444-5555" }
    parentworkphone { "123-666-5555" }
    parentemail { Faker::Internet.email }
  end
end
