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

  describe 'formula injection guard' do
    it 'prefixes strings that a spreadsheet would evaluate and leaves everything else alone' do
      export = described_class.define do
        column('Message') { |row| row[:message] }
        column('Balance') { |row| row[:balance] }
        column('Count') { |row| row[:count] }
        column('When') { |row| row[:when] }
      end
      rows = [
        { message: '=HYPERLINK("https://evil.example","click")', balance: Money.new(-2500, 'USD'), count: -3, when: Date.new(2030, 1, 2) },
        { message: '+1 for this', balance: Money.new(500, 'USD'), count: 0, when: nil },
        { message: '-not a number', balance: nil, count: 4.5, when: nil },
        { message: '@mention', balance: nil, count: nil, when: nil },
        { message: "\tleading tab", balance: nil, count: nil, when: nil },
        { message: 'Plain text with = inside', balance: nil, count: nil, when: nil }
      ]

      csv = CSV.parse(export.generate(rows))

      expect(csv.map(&:first)).to eq(
        ['Message', %q('=HYPERLINK("https://evil.example","click")), %q('+1 for this), %q('-not a number), %q('@mention),
         "'\tleading tab", 'Plain text with = inside']
      )
      expect(csv[1][1]).to eq(Money.new(-2500, 'USD').format)
      expect(csv[1][1]).not_to start_with("'")
      expect(csv[1][2]).to eq('-3')
      expect(csv[1][3]).to eq('2030-01-02')
      expect(csv[3][2]).to eq('4.5')
    end

    it 'also guards raw-SQL report rows' do
      result = ActiveRecord::Result.new(%w[name amount], [['=cmd|calc', 12], ['Ada', -3]])

      rows = CSV.parse(described_class.report(result, title: 'names'))

      expect(rows[3]).to eq(["'=cmd|calc", '12'])
      expect(rows[4]).to eq(['Ada', '-3'])
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

    it 'formats report cells like column exports (Money, dates, BigDecimal) without guarding them' do
      result = ActiveRecord::Result.new(%w[name balance ratio born],
                                        [['Ada', Money.new(-2500, 'USD'), BigDecimal('1234.5'), Date.new(2008, 5, 12)]])

      rows = CSV.parse(described_class.report(result, title: 'balances'))

      expect(rows.last).to eq(['Ada', Money.new(-2500, 'USD').format, '1234.5', '2008-05-12'])
      expect(rows.last[1]).not_to start_with("'")
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
