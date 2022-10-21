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
require 'rails_helper'

RSpec.describe ApplicantDetail, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
