# == Schema Information
#
# Table name: applicant_details
#
#  id                 :bigint           not null, primary key
#  user_id            :bigint           not null
#  firstname          :string(255)      not null
#  middlename         :string(255)
#  lastname           :string(255)      not null
#  gender             :string(255)
#  us_citizen         :boolean          default(FALSE), not null
#  birthdate          :date             not null
#  diet_restrictions  :text(65535)
#  shirt_size         :string(255)
#  address1           :string(255)      not null
#  address2           :string(255)
#  city               :string(255)      not null
#  state              :string(255)      not null
#  state_non_us       :string(255)
#  postalcode         :string(255)      not null
#  country            :string(255)      not null
#  phone              :string(255)      not null
#  parentname         :string(255)      not null
#  parentaddress1     :string(255)
#  parentaddress2     :string(255)
#  parentcity         :string(255)
#  parentstate        :string(255)
#  parentstate_non_us :string(255)
#  parentzip          :string(255)
#  parentcountry      :string(255)
#  parentphone        :string(255)      not null
#  parentworkphone    :string(255)
#  parentemail        :string(255)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  demographic_id     :bigint
#  demographic_other  :string(255)
#
FactoryBot.define do
  factory :applicant_detail do
    association :user
    demographic { Demographic.first || association(:demographic) }
    firstname { Faker::Name.first_name }
    middlename { Faker::Name.middle_name }
    lastname { Faker::Name.last_name }
    gender { Gender.first&.id || association(:gender) }
    birthdate { Faker::Date.birthday(min_age: 15, max_age: 18) }
    diet_restrictions { 'peanuts' }
    shirt_size { 'Large' }
    address1 { Faker::Address.street_address }
    address2 { Faker::Address.secondary_address }
    city { Faker::Address.city }
    state { Faker::Address.state_abbr }
    postalcode { Faker::Address.zip_code }
    country { 'US' }
    phone { '123-333-5555' }
    parentname { Faker::Name.name }
    parentaddress1 { Faker::Address.street_address }
    parentaddress2 { Faker::Address.secondary_address }
    parentcity { Faker::Address.city }
    parentstate { Faker::Address.state_abbr }
    parentzip { Faker::Address.zip_code }
    parentcountry { 'US' }
    parentphone { '123-444-5555' }
    parentworkphone { '123-666-5555' }
    parentemail { Faker::Internet.email }

    after(:build) do |applicant_detail|
      if applicant_detail.demographic&.name&.downcase == 'other'
        applicant_detail.demographic_other = 'Other Demographic Details'
      end
    end
  end
end
