# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::ApplicationsHelper, type: :helper do
  describe '#admin_application_status_options' do
    it 'returns the admin STATUS_OPTIONS for a blank status' do
      application = build_stubbed(:enrollment, application_status: nil)

      expect(helper.admin_application_status_options(application))
        .to eq(Admin::ApplicationsController::STATUS_OPTIONS)
    end

    it 'appends a persisted status that is not in STATUS_OPTIONS so the select cannot clear it' do
      application = build_stubbed(:enrollment, application_status: 'withdrawn')

      options = helper.admin_application_status_options(application)

      expect(options).to include(*Admin::ApplicationsController::STATUS_OPTIONS)
      expect(options).to include('withdrawn')
      expect(options.count('withdrawn')).to eq(1)
    end

    it 'does not duplicate a status that is already in STATUS_OPTIONS' do
      application = build_stubbed(:enrollment, application_status: 'enrolled')

      expect(helper.admin_application_status_options(application))
        .to eq(Admin::ApplicationsController::STATUS_OPTIONS)
    end
  end
end
