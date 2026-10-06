# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::SessionAssignmentsHelper, type: :helper do
  describe '#admin_session_assignment_offer_status_options' do
    it 'returns the admin OFFER_STATUS_OPTIONS for a blank offer status' do
      session_assignment = build_stubbed(:session_assignment, offer_status: nil)

      expect(helper.admin_session_assignment_offer_status_options(session_assignment))
        .to eq(Admin::SessionAssignmentsController::OFFER_STATUS_OPTIONS)
    end

    it 'appends a persisted offer status that is not in OFFER_STATUS_OPTIONS so the select cannot clear it' do
      session_assignment = build_stubbed(:session_assignment, offer_status: 'offered')

      options = helper.admin_session_assignment_offer_status_options(session_assignment)

      expect(options).to include(*Admin::SessionAssignmentsController::OFFER_STATUS_OPTIONS)
      expect(options).to include('offered')
      expect(options.count('offered')).to eq(1)
    end

    it 'does not duplicate an offer status that is already in OFFER_STATUS_OPTIONS' do
      session_assignment = build_stubbed(:session_assignment, offer_status: 'accepted')

      expect(helper.admin_session_assignment_offer_status_options(session_assignment))
        .to eq(Admin::SessionAssignmentsController::OFFER_STATUS_OPTIONS)
    end
  end
end
