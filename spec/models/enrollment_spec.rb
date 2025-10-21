# == Schema Information
#
# Table name: enrollments
#
require 'rails_helper'

RSpec.describe Enrollment, type: :model do
  before { setup_basic_test_data }

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_one(:applicant_detail).through(:user) }
    it { is_expected.to have_many(:enrollment_activities).dependent(:destroy) }
    it { is_expected.to have_many(:session_activities).dependent(:destroy) }
    it { is_expected.to have_many(:session_assignments).dependent(:destroy) }
    it { is_expected.to have_many(:course_preferences).dependent(:destroy) }
    it { is_expected.to have_many(:course_assignments).dependent(:destroy) }
    it { is_expected.to have_many(:financial_aids).dependent(:destroy) }
    it { is_expected.to have_many(:travels).dependent(:destroy) }
    it { is_expected.to have_one(:recommendation).dependent(:destroy) }
    it { is_expected.to have_one(:rejection).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:enrollment) }

    it { is_expected.to validate_presence_of(:high_school_name) }
    it { is_expected.to validate_presence_of(:high_school_address1) }
    it { is_expected.to validate_presence_of(:high_school_city) }
    it { is_expected.to validate_presence_of(:high_school_country) }
    it { is_expected.to validate_presence_of(:year_in_school) }
    it { is_expected.to validate_presence_of(:anticipated_graduation_year) }
    it { is_expected.to validate_presence_of(:personal_statement) }
    it { is_expected.to validate_length_of(:personal_statement).is_at_least(100) }
  end

  describe 'attachments' do
    it { is_expected.to have_one_attached(:transcript) }
    it { is_expected.to have_one_attached(:student_packet) }
    it { is_expected.to have_one_attached(:vaccine_record) }
    it { is_expected.to have_one_attached(:covid_test_record) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      enrollment = build(:enrollment)
      expect(enrollment).to be_valid
    end

    it 'creates international enrollment with trait' do
      enrollment = create(:enrollment, :international)
      expect(enrollment.international).to be true
      expect(enrollment.high_school_country).not_to eq('US')
    end

    it 'creates enrollment with different statuses' do
      expect(create(:enrollment, :offered).offer_status).to eq('offered')
      expect(create(:enrollment, :accepted).offer_status).to eq('accepted')
      expect(create(:enrollment, :enrolled).application_status).to eq('enrolled')
    end
  end

  describe '#display_name' do
    let(:user) { create(:user) }
    let!(:applicant_detail) { create(:applicant_detail, user: user, firstname: 'John', lastname: 'Doe') }
    let(:enrollment) { create(:enrollment, user: user) }

    it 'returns full name and email' do
      expect(enrollment.display_name).to eq("Doe, John - #{user.email}")
    end
  end

  describe 'scopes' do
    let(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year) }

    before do
      CampConfiguration.update_all(active: false)
      camp_config.update(active: true)
    end

    describe '.current_camp_year_applications' do
      let!(:current_enrollment) { create(:enrollment, campyear: Date.current.year) }
      let!(:old_enrollment) { create(:enrollment, campyear: Date.current.year - 1) }

      it 'returns enrollments for current camp year' do
        expect(Enrollment.current_camp_year_applications).to include(current_enrollment)
        expect(Enrollment.current_camp_year_applications).not_to include(old_enrollment)
      end
    end

    describe '.offered' do
      let!(:offered_enrollment) { create(:enrollment, :offered, campyear: Date.current.year) }
      let!(:regular_enrollment) { create(:enrollment, campyear: Date.current.year) }

      it 'returns offered enrollments' do
        expect(Enrollment.offered).to include(offered_enrollment)
        expect(Enrollment.offered).not_to include(regular_enrollment)
      end
    end

    describe '.enrolled' do
      let!(:enrolled_enrollment) { create(:enrollment, :enrolled, campyear: Date.current.year) }
      let!(:offered_enrollment) { create(:enrollment, :offered, campyear: Date.current.year) }

      it 'returns enrolled students' do
        expect(Enrollment.enrolled).to include(enrolled_enrollment)
        expect(Enrollment.enrolled).not_to include(offered_enrollment)
      end
    end
  end

  describe 'callbacks' do
    describe 'setting application_fee_required' do
      let(:camp_config) { create(:camp_configuration, :active, application_fee_required: false) }

      before do
        CampConfiguration.update_all(active: false)
        camp_config.update(active: true)
      end

      it 'sets application_fee_required based on active camp configuration' do
        enrollment = create(:enrollment)
        expect(enrollment.application_fee_required).to be false
      end
    end

    describe 'email notifications' do
      let(:user) { create(:user) }
      let!(:applicant_detail) { create(:applicant_detail, user: user) }
      let(:enrollment) { create(:enrollment, user: user) }

      it 'sends offer email when offer_status changes to offered' do
        expect(OfferMailer).to receive(:offer_email).with(user.id).and_return(double(deliver_now: true))
        enrollment.update(offer_status: 'offered')
      end

      it 'sends enrolled email when application_status changes to enrolled' do
        expect(RegistrationMailer).to receive(:app_enrolled_email).with(user).and_return(double(deliver_now: true))
        enrollment.update(application_status: 'enrolled')
      end

      it 'sends rejected email when application_status changes to rejected' do
        expect(RejectedMailer).to receive(:app_rejected_email).with(enrollment).and_return(double(deliver_now: true))
        enrollment.update(application_status: 'rejected')
      end

      it 'sends waitlisted email when application_status changes to waitlisted' do
        expect(WaitlistedMailer).to receive(:app_waitlisted_email).with(enrollment).and_return(double(deliver_now: true))
        enrollment.update(application_status: 'waitlisted')
      end
    end
  end

  describe '#update_status_based_on_session_assignments!' do
    let(:enrollment) { create(:enrollment) }
    let(:session1) { create(:camp_occurrence) }
    let(:session2) { create(:camp_occurrence) }

    context 'when all assignments are declined' do
      before do
        create(:session_assignment, enrollment: enrollment, camp_occurrence: session1, offer_status: 'declined')
        create(:session_assignment, enrollment: enrollment, camp_occurrence: session2, offer_status: 'declined')
      end

      it 'updates enrollment to declined status' do
        enrollment.update_status_based_on_session_assignments!
        expect(enrollment.offer_status).to eq('declined')
        expect(enrollment.application_status).to eq('offer declined')
      end
    end

    context 'when all assignments are accepted' do
      before do
        create(:session_assignment, enrollment: enrollment, camp_occurrence: session1, offer_status: 'accepted')
        create(:session_assignment, enrollment: enrollment, camp_occurrence: session2, offer_status: 'accepted')
      end

      it 'updates enrollment to accepted status' do
        enrollment.update_status_based_on_session_assignments!
        expect(enrollment.offer_status).to eq('accepted')
        expect(enrollment.application_status).to eq('offer accepted')
      end
    end

    context 'when assignments have mixed statuses' do
      before do
        create(:session_assignment, enrollment: enrollment, camp_occurrence: session1, offer_status: 'accepted')
        create(:session_assignment, enrollment: enrollment, camp_occurrence: session2, offer_status: nil)
      end

      it 'does not update enrollment status' do
        original_status = enrollment.offer_status
        enrollment.update_status_based_on_session_assignments!
        expect(enrollment.offer_status).to eq(original_status)
      end
    end
  end

  it_behaves_like 'a model with timestamps'
end
