# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::MoneyInput do
  it 'parses plain, decimal, dollar-prefixed and properly grouped amounts to whole cents' do
    expect(described_class.parse_cents('150')).to eq(15_000)
    expect(described_class.parse_cents('1500.5')).to eq(150_050)
    expect(described_class.parse_cents('1,500.50')).to eq(150_050)
    expect(described_class.parse_cents('$1,234,567.89')).to eq(123_456_789)
    expect(described_class.parse_cents(' 0 ')).to eq(0)
  end

  it 'rejects signs, exponents, extra decimals, non-numbers and arbitrary comma placement' do
    ['-5', '+5', 'abc', 'Infinity', 'NaN', '1e3', '12.345', '0x10', '1,2,3', '12,34.5', '1,,000', ',500', '1500,', ''].each do |bad|
      expect(described_class.parse_cents(bad)).to be_nil, "#{bad.inspect} was accepted"
      expect(described_class.valid?(bad)).to be(false)
    end
  end
end
