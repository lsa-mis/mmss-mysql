require 'rails_helper'

RSpec.describe 'Application status application_status_updated_on', type: :system do

  before :each do
    load "#{Rails.root}/spec/system/test_seeds.rb" 
    @user = FactoryBot.create(:user)
    login_as(@user)
  end

  context 'creates application_status_updated_on' do
    let!(:user) { FactoryBot.create(:user) }
    let!(:applicant_detail) { FactoryBot.create(:applicant_detail, user: user) }
    let!(:session_registration_ids) { CampOccurrence.all.pluck(:id)}
    let!(:course_registration_ids) { Course.where(camp_occurrence_id: session_registration_ids).pluck(:id)}
    let!(:enrollment) { FactoryBot.create(:enrollment, user: user, session_registration_ids: session_registration_ids, course_registration_ids: course_registration_ids) }

    it 'when application_status changed to submitted' do
      
    end

    it 'when application_status changed to application complete' do
      
    end

    it 'when application_status changed to offer accepted' do
      
    end

    it 'when application_status changed to offer declined' do
      
    end


    it 'when application_status changed to rejected' do
      
    end

    it 'when application_status changed to waitlisted' do
      
    end

    it 'when application_status changed to enrolled' do
      
    end
  end

end