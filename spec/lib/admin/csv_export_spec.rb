# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::CsvExport do
  describe '.define / #generate' do
    let(:export) do
      described_class.define do
        column :description
        column :active
        column('Cost') { |activity| activity.cost }
        column :date_occurs, header: 'When'
      end
    end

    it 'renders a header row and formatted values' do
      activity = create(:activity, description: 'Cedar Point', active: true, cost_cents: 8500, date_occurs: Date.new(2030, 7, 4))

      rows = CSV.parse(export.generate([activity]))

      expect(rows[0]).to eq(%w[Description Active Cost When])
      expect(rows[1]).to eq(['Cedar Point', 'true', '$85.00', '2030-07-04'])
    end
  end

  describe '.report' do
    it 'mirrors the raw-SQL report layout (title, total row, upper-cased headers)' do
      result = ActiveRecord::Result.new(%w[first_name camp_year], [['Ada', 2030], ['Grace', 2031]])

      rows = CSV.parse(described_class.report(result, title: 'all_complete_apps'))

      expect(rows).to eq([
        ['All Complete Apps'],
        ['Total number of records: 2'],
        ['FIRST NAME', 'CAMP YEAR'],
        %w[Ada 2030],
        %w[Grace 2031]
      ])
    end

    it 'accepts custom headers and a row transform' do
      result = ActiveRecord::Result.new(%w[name balance_cents], [['Ada', 12_345]])

      csv = described_class.report(result, title: 'balance', headers: %w[NAME BALANCE\ DUE]) do |row|
        [row[0], format('%.2f', row[1] / 100.0)]
      end

      expect(CSV.parse(csv).last(2)).to eq([%w[NAME BALANCE\ DUE], ['Ada', '123.45']])
    end
  end

  it 'builds dated filenames' do
    expect(described_class.filename('applications')).to match(/\AMMSS-applications-[A-Z][a-z]{2}-\d{1,2}-\d{4}\.csv\z/)
  end
end
