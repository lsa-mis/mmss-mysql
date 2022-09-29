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
    # middlename { "The" }
    lastname { Faker::Name.last_name }
    gender { Faker::Gender.binary_type }
    us_citizen { Faker::Boolean.boolean }
    demographic { Faker::Demographic.race }
    birthdate { Faker::Date.birthday(min_age: 15, max_age: 18) }
    diet_restrictions { "peanuts" }
    shirt_size { "Large" }
    address1 { Faker::Address.street_address }
    # address2 { "MyString" }
    city { Faker::Address.city }
    state { Faker::Address.state_abbr }
    # state_non_us { "MyString" }
    postalcode { Faker::Address.zip_code }
    country { "US" }
    # phone { Faker::PhoneNumber.cell_phone }
    phone { "123-444-5555" }
    parentname { Faker::Name.name }
    parentaddress1 { Faker::Address.street_address }
    # parentaddress2 { "MyString" }
    parentcity { Faker::Address.city }
    # parentstate { "MyString" }
    # parentstate_non_us { "MyString" }
    parentzip { Faker::Address.zip_code  }
    parentcountry { "US" }
    parentphone { "123-444-5555" }
    # parentworkphone { "MyString" }
    parentemail { Faker::Internet.email }
  end
end
