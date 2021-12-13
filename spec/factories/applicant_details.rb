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
#  demographic        :string(255)
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
#
FactoryBot.define do
  factory :applicant_detail do
    user
    firstname { "Chester" }
    # middlename { "The" }
    lastname { "Tester" }
    gender { "Male" }
    us_citizen { true }
    demographic { "MyString" }
    birthdate { "2019-07-22" }
    diet_restrictions { "peanuts" }
    shirt_size { "Large" }
    address1 { "123 Main Street" }
    # address2 { "MyString" }
    city { "Saline" }
    # state { "MyString" }
    # state_non_us { "MyString" }
    postalcode { "48896" }
    country { "US" }
    phone { "1234567890" }
    parentname { "Cheryl Stooge" }
    parentaddress1 { "123 Main Street" }
    # parentaddress2 { "MyString" }
    parentcity { "Saline" }
    # parentstate { "MyString" }
    # parentstate_non_us { "MyString" }
    parentzip { "48896" }
    parentcountry { "US" }
    parentphone { "9876543217" }
    # parentworkphone { "MyString" }
    parentemail { "cheryl.tester@tester.com" }
  end
end
