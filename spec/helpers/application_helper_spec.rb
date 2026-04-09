# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#show_applicant_progress_window?' do
    it 'returns false when not signed in' do
      allow(helper).to receive(:user_signed_in?).and_return(false)
      expect(helper.show_applicant_progress_window?).to be false
    end

    context 'when signed in' do
      let(:user) { instance_double(User) }

      before do
        allow(helper).to receive(:user_signed_in?).and_return(true)
        allow(helper).to receive(:current_user).and_return(user)
      end

      it 'returns true when registration is open' do
        allow(helper).to receive(:registration_open?).and_return(true)
        expect(helper.show_applicant_progress_window?).to be true
      end

      context 'when registration is closed' do
        before { allow(helper).to receive(:registration_open?).and_return(false) }

        it 'returns false without applicant detail' do
          allow(user).to receive(:applicant_detail).and_return(nil)
          expect(helper.show_applicant_progress_window?).to be false
        end

        it 'returns true with persisted applicant detail and current year enrollment' do
          applicant_detail = instance_double(ApplicantDetail, persisted?: true)
          allow(user).to receive(:applicant_detail).and_return(applicant_detail)
          enrollment_chain = instance_double('EnrollmentRelation')
          allow(user).to receive(:enrollments).and_return(enrollment_chain)
          allow(enrollment_chain).to receive(:current_camp_year_applications).and_return(enrollment_chain)
          allow(enrollment_chain).to receive(:last).and_return(instance_double(Enrollment))

          expect(helper.show_applicant_progress_window?).to be true
        end

        it 'returns false with applicant detail but no enrollment' do
          applicant_detail = instance_double(ApplicantDetail, persisted?: true)
          allow(user).to receive(:applicant_detail).and_return(applicant_detail)
          enrollment_chain = instance_double('EnrollmentRelation')
          allow(user).to receive(:enrollments).and_return(enrollment_chain)
          allow(enrollment_chain).to receive(:current_camp_year_applications).and_return(enrollment_chain)
          allow(enrollment_chain).to receive(:last).and_return(nil)

          expect(helper.show_applicant_progress_window?).to be false
        end
      end
    end
  end

  describe '#applicant_status' do
    it 'includes all status options including withdrawn' do
      statuses = helper.applicant_status

      expect(statuses).to include(['*Select*', ''])
      expect(statuses).to include(['enrolled', 'enrolled'])
      expect(statuses).to include(['application complete', 'application complete'])
      expect(statuses).to include(['offer accepted', 'offer accepted'])
      expect(statuses).to include(['offer declined', 'offer declined'])
      expect(statuses).to include(['submitted', 'submitted'])
      expect(statuses).to include(['withdrawn', 'withdrawn'])
    end

    it 'has withdrawn as the last option' do
      statuses = helper.applicant_status
      expect(statuses.last).to eq(['withdrawn', 'withdrawn'])
    end
  end

  describe '#session_expires_at' do
    let(:current_time) { Time.zone.parse('2024-01-01 12:00:00') }
    let(:four_hours_in_seconds) { 4.hours.to_i }

    before do
      allow(Time.zone).to receive(:now).and_return(current_time)
      allow(Time).to receive(:current).and_return(current_time)
    end

    context 'when session is not present' do
      it 'returns nil when session is not present' do
        # Stub authentication helpers to return false
        allow(helper).to receive(:user_signed_in?).and_return(false)
        allow(helper).to receive(:admin_signed_in?).and_return(false)
        allow(helper).to receive(:faculty_signed_in?).and_return(false)
        expect(helper.session_expires_at).to be_nil
      end
    end

    context 'when session is present' do
      before do
        # Stub authentication helpers to return true (user is signed in)
        allow(helper).to receive(:user_signed_in?).and_return(true)
        allow(helper).to receive(:admin_signed_in?).and_return(false)
        allow(helper).to receive(:faculty_signed_in?).and_return(false)
      end

      context 'in production environment' do
        before do
          allow(Rails.env).to receive(:production?).and_return(true)
          allow(Rails.env).to receive(:staging?).and_return(false)
        end

        it 'returns a Unix timestamp' do
          result = helper.session_expires_at
          expect(result).to be_a(Integer)
          expect(result).to be > 0
        end

        it 'returns timestamp approximately 4 hours from current time' do
          result = helper.session_expires_at
          expected_time = current_time.to_i + four_hours_in_seconds
          expect(result).to eq(expected_time)
        end
      end

      context 'in staging environment' do
        before do
          allow(Rails.env).to receive(:production?).and_return(false)
          allow(Rails.env).to receive(:staging?).and_return(true)
        end

        it 'returns a Unix timestamp' do
          result = helper.session_expires_at
          expect(result).to be_a(Integer)
          expect(result).to be > 0
        end

        it 'returns timestamp approximately 4 hours from current time' do
          result = helper.session_expires_at
          expected_time = current_time.to_i + four_hours_in_seconds
          expect(result).to eq(expected_time)
        end
      end

      context 'in development environment' do
        before do
          allow(Rails.env).to receive(:production?).and_return(false)
          allow(Rails.env).to receive(:staging?).and_return(false)
        end

        it 'returns a Unix timestamp' do
          result = helper.session_expires_at
          expect(result).to be_a(Integer)
          expect(result).to be > 0
        end

        it 'returns timestamp approximately 4 hours from current time' do
          result = helper.session_expires_at
          expected_time = current_time.to_i + four_hours_in_seconds
          expect(result).to eq(expected_time)
        end
      end
    end
  end
end
