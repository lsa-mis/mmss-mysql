# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentRequest, '#requested_at', type: :model do
  it 'keeps the millisecond portion of the Nelnet epoch-ms timestamp' do
    request = build(:payment_request, request_timestamp: 1_704_067_200_250)

    expect(request.requested_at).to eq(Time.zone.at(1_704_067_200.250))
    expect(request.requested_at.usec).to eq(250_000)
  end

  it 'returns nil when request_timestamp is blank' do
    request = build(:payment_request, request_timestamp: nil)

    expect(request.requested_at).to be_nil
  end
end
