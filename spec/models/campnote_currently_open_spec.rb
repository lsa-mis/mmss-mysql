# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Campnote, '.currently_open' do
  it 'returns notes whose window covers now and ignores closed, future and undated notes' do
    open_note = create(:campnote, opendate: 1.hour.ago, closedate: 1.hour.from_now)
    create(:campnote, opendate: 2.days.ago, closedate: 1.day.ago)
    create(:campnote, opendate: 1.day.from_now, closedate: 2.days.from_now)
    undated = build(:campnote, opendate: nil, closedate: nil)
    undated.save(validate: false)

    expect(Campnote.currently_open).to eq([open_note])
  end
end
