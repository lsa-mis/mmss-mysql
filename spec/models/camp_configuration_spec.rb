# == Schema Information
#
# Table name: camp_configurations
#
#  id                        :bigint           not null, primary key
#  camp_year                 :integer          not null
#  application_open          :date             not null
#  application_close         :date             not null
#  priority                  :date             not null
#  application_materials_due :date             not null
#  camper_acceptance_due     :date             not null
#  active                    :boolean          default(FALSE), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  offer_letter              :text(65535)
#  student_packet_url        :string(255)
#  application_fee_cents     :integer
#  reject_letter             :text(65535)
#  waitlist_letter           :text(65535)
#
require 'rails_helper'

RSpec.describe CampConfiguration, type: :model do
  context "all required fields are present" do
    subject { build(:camp_configuration) } 

    it 'is valid' do
      expect(subject).to be_valid
    end
    
  end

  context "required fields are not blank" do
    it { should validate_presence_of(:camp_year) }
    it { should validate_presence_of(:application_open) }
    it { should validate_presence_of(:application_close) }
    it { should validate_presence_of(:priority) }
    it { should validate_presence_of(:application_materials_due) }
    it { should validate_presence_of(:camper_acceptance_due) }
    
  end
  
end
