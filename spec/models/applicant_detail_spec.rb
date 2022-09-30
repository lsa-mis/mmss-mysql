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

  context "the Factory" do
    it 'is valid' do
      build(:applicant_detail).should be_valid
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
