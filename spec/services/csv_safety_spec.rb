# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CsvSafety do
  describe '.cell' do
    it 'prefixes formula-like values' do
      expect(described_class.cell('=1+1')).to eq("'=1+1")
      expect(described_class.cell('+1234')).to eq("'+1234")
      expect(described_class.cell('-1234')).to eq("'-1234")
      expect(described_class.cell('@SUM(A1)')).to eq("'@SUM(A1)")
      expect(described_class.cell('=HYPERLINK("http://evil.example")')).to eq("'=HYPERLINK(\"http://evil.example\")")
    end

    it 'leaves ordinary text and non-strings unchanged' do
      expect(described_class.cell('Alice')).to eq('Alice')
      expect(described_class.cell('')).to eq('')
      expect(described_class.cell(nil)).to be_nil
      expect(described_class.cell(42)).to eq(42)
      expect(described_class.cell(true)).to eq(true)
    end

    it 'neutralizes formula triggers after ignorable leading whitespace or controls' do
      [
        ' =1+1',
        "\u00A0+cmd",
        "\uFEFF@SUM(A1)",
        "\v=HYPERLINK(\"http://evil.example\")",
        "\f-1+1",
        "\t\r\n =WEBSERVICE(\"http://evil.example\")"
      ].each do |payload|
        expect(described_class.cell(payload)).to eq("'#{payload}")
      end

      expect(described_class.cell(' ordinary')).to eq(' ordinary')
      expect(described_class.cell("\u00A0safe")).to eq("\u00A0safe")
    end
  end

  describe '.row' do
    it 'maps each cell through formula neutralization' do
      expect(described_class.row(['Alice', '=1+1', 7, nil])).to eq(['Alice', "'=1+1", 7, nil])
    end
  end
end
