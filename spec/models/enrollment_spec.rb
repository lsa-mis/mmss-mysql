# == Schema Information
#
# Table name: enrollments
#
#  id                            :bigint           not null, primary key
#  user_id                       :bigint           not null
#  international                 :boolean          default(FALSE), not null
#  high_school_name              :string(255)      not null
#  high_school_address1          :string(255)      not null
#  high_school_address2          :string(255)
#  high_school_city              :string(255)      not null
#  high_school_state             :string(255)
#  high_school_non_us            :string(255)
#  high_school_postalcode        :string(255)
#  high_school_country           :string(255)      not null
#  year_in_school                :string(255)      not null
#  anticipated_graduation_year   :string(255)      not null
#  room_mate_request             :string(255)
#  personal_statement            :text(65535)      not null
#  notes                         :text(65535)
#  application_status            :string(255)
#  offer_status                  :string(255)
#  partner_program               :string(255)
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  campyear                      :integer
#  application_deadline          :date
#  application_status_updated_on :date
#  uniqname                      :string(255)
#  camp_doc_form_completed       :boolean          default(FALSE)
#  application_fee_required      :boolean          default(TRUE), not null
#
require 'rails_helper'

RSpec.describe Enrollment, type: :model do

  before :each do
    load "#{Rails.root}/spec/test_seeds.rb" 
  end

  context "all required fields are present" do
    let!(:user) { FactoryBot.create(:user) }
    let!(:applicant_detail) { FactoryBot.create(:applicant_detail, user: user) }
    let!(:session_registration_ids) { CampOccurrence.all.pluck(:id)}
    let!(:course_registration_ids) { Course.where(camp_occurrence_id: session_registration_ids).pluck(:id)}

    it 'test database' do
      expect(ActiveRecord::Base.connection_config[:database]).to match(/test/)
    end

    it 'is valid' do
      expect(FactoryBot.create(:enrollment, user: user, session_registration_ids: session_registration_ids, course_registration_ids: course_registration_ids))
        .to be_valid
    end

    it 'not valid without session_registration' do
      session_registration_ids = []
      course_registration_ids = []
      expect { (FactoryBot.create(:enrollment, user: user, session_registration_ids: session_registration_ids, course_registration_ids: course_registration_ids)) }
        .to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Select at least one session, Select at least one course")
    end

    it 'not valid without course_registration' do
      course_registration_ids = []
      expect { (FactoryBot.create(:enrollment, user: user, session_registration_ids: session_registration_ids, course_registration_ids: course_registration_ids)) }
        .to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Select at least one course")
    end

    it 'prevent creating second enrollment records for a user for the current camp' do
      enroll1 = FactoryBot.create(:enrollment, user: user, session_registration_ids: session_registration_ids, course_registration_ids: course_registration_ids)
      expect(enroll1).to be_valid
      expect { (FactoryBot.create(:enrollment, user: user, session_registration_ids: session_registration_ids, course_registration_ids: course_registration_ids)) }
        .to raise_error(ActiveRecord::RecordInvalid, "Validation failed: User has already been taken")
    end
  end
end
