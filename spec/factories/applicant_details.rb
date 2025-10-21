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
    transient do
      ensure_demographic { true }
    end

    demographic do
      if ensure_demographic
        Demographic.first || create(:demographic)
      else
        create(:demographic)
      end
    end

    firstname { Faker::Name.first_name }
    middlename { Faker::Name.middle_name }
    lastname { Faker::Name.last_name }

    gender do
      gender_record = Gender.first
      gender_record&.id || create(:gender).id
    end

    us_citizen { true }
    birthdate { Faker::Date.birthday(min_age: 15, max_age: 18) }
    diet_restrictions { ['Peanuts', 'Gluten', 'Dairy', 'Shellfish', nil].sample }
    shirt_size { ['Small', 'Medium', 'Large', 'X-Large', 'XX-Large'].sample }

    # Applicant address
    address1 { Faker::Address.street_address }
    address2 { [nil, Faker::Address.secondary_address].sample }
    city { Faker::Address.city }
    state { Faker::Address.state_abbr }
    state_non_us { nil }
    postalcode { Faker::Address.zip_code }
    country { 'US' }
    sequence(:phone) { |n| "+1-555-#{format('%04d', n + 5000)}" }

    # Parent/Guardian information
    parentname { Faker::Name.name }
    parentaddress1 { Faker::Address.street_address }
    parentaddress2 { [nil, Faker::Address.secondary_address].sample }
    parentcity { Faker::Address.city }
    parentstate { Faker::Address.state_abbr }
    parentstate_non_us { nil }
    parentzip { Faker::Address.zip_code }
    parentcountry { 'US' }
    sequence(:parentphone) { |n| "+1-555-#{format('%04d', n)}" }
    sequence(:parentworkphone) { |n| "+1-555-#{format('%04d', n + 10000)}" }
    sequence(:parentemail) { |n| "parent#{n}@example.com" }

    # Traits for different scenarios
    trait :international do
      us_citizen { false }
      country { Faker::Address.country_code }
      state { 'Non-US' }
      state_non_us { Faker::Address.state }
    end

    trait :domestic do
      us_citizen { true }
      country { 'US' }
      state { Faker::Address.state_abbr }
      state_non_us { nil }
    end

    trait :with_other_demographic do
      demographic { Demographic.find_or_create_by!(name: 'Other', description: 'Other option', protected: true) }
      demographic_other { 'Custom demographic information' }
    end

    trait :minimal do
      middlename { nil }
      address2 { nil }
      diet_restrictions { nil }
      parentaddress1 { nil }
      parentaddress2 { nil }
      parentcity { nil }
      parentstate { nil }
      parentzip { nil }
      parentcountry { nil }
      parentworkphone { nil }
    end

    after(:build) do |applicant_detail|
      # Ensure parent email is different from user email
      if applicant_detail.user && applicant_detail.parentemail == applicant_detail.user.email
        applicant_detail.parentemail = "parent_#{applicant_detail.user.email}"
      end

      # Handle demographic_other for "Other" demographic
      if applicant_detail.demographic&.name&.downcase == 'other' && applicant_detail.demographic_other.blank?
        applicant_detail.demographic_other = 'Other demographic details'
      end
    end
  end
end
