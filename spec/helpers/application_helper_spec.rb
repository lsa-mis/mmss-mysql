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
end
