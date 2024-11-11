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
require 'rails_helper'

RSpec.describe ApplicantDetail, type: :model do

  context "the Factory" do
    it 'is valid' do
      expect(build(:applicant_detail)).to be_valid
    end
  end

  context "all required fields are present" do
    subject { 
      FactoryBot.create(:user)
      FactoryBot.create(:applicant_detail) } 

    it 'is valid' do
      expect(subject).to be_valid
    end
  end

  context "without first name" do
    let!(:user) { FactoryBot.create(:user) }

    it 'is not valid' do
      expect { (FactoryBot.create(:applicant_detail, firstname: "", user: user)) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Firstname can't be blank")
    end
  end

  context "prevent to create two ApplicantDetail records for a user (test user uniqueness)" do
    let!(:user) { FactoryBot.create(:user) }
    it 'is valid' do
      appdet1 = FactoryBot.create(:applicant_detail, user: user)
      expect(appdet1).to be_valid
      expect { (FactoryBot.create(:applicant_detail, user: user)) }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: User has already been taken")
    end
  end
end
