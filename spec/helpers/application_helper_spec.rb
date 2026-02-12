# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
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
