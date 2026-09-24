# frozen_string_literal: true

require 'rails_helper'

# Every registered report must keep executing against the current schema and keep its column set;
# a renamed column or table breaks a report only at download time otherwise.
RSpec.describe Admin::Reports, :admin_reports do
  let(:camp) { create(:camp_configuration, :current_year) }

  it 'registers the eighteen ActiveAdmin reports in two groups with unique keys' do
    expect(described_class.all.size).to eq(18)
    expect(described_class::GROUPS.keys).to eq(['Applications', 'Enrolled students'])
    expect(described_class.keys).to match_array(AdminReportFixtures::EXPECTED_HEADERS.keys)
    expect(described_class.keys.uniq.size).to eq(18)
  end

  it 'finds reports by key only' do
    expect(described_class.find('all_complete_apps')).to eq(Admin::Reports::AllCompleteApps)
    expect(described_class.find(:course_assignments)).to eq(Admin::Reports::CourseAssignments)
    expect(described_class.find('nope')).to be_nil
    expect(described_class.find('all_complete_apps; DROP TABLE users')).to be_nil
    expect(described_class.find(nil)).to be_nil
  end

  described_class.all.each do |report_class|
    describe report_class.name do
      it 'declares its metadata and one camp-year parameter' do
        expect(report_class.label).to be_present
        expect(report_class.description).to be_present
        expect(report_class.csv_title).to match(/\A[a-z_]+\z/)
        expect(report_class.sql).to include(':camp_year')
        expect(report_class.parameters).to eq([:camp_year])
      end

      it 'binds the camp values and leaves no placeholder or interpolation behind' do
        sql = report_class.new(camp).bound_sql

        expect(sql).not_to include(':camp_year')
        expect(sql).not_to include(':camp_id')
        expect(sql).not_to include('#{')
        expect(sql).to include(camp.camp_year.to_s)
      end

      it 'executes against the schema with the expected columns on an empty camp' do
        result = report_class.new(camp).result

        expect(result.columns.map { |column| column.titleize.upcase }).to eq(AdminReportFixtures::EXPECTED_HEADERS[report_class.key])
        expect(result.rows).to eq([])
        expect(report_class.new(camp).rows).to eq([])
      end
    end
  end

  describe 'with a seeded camp' do
    let(:fixtures) { build_report_fixtures }
    let(:camp) { fixtures.camp }

    it 'returns at least one row from every report' do
      described_class.all.each do |report_class|
        expect(report_class.new(camp).rows.size).to be >= 1, "#{report_class.key} returned no rows"
      end
    end

    it 'only sees the selected camp year' do
      other_camp = create(:camp_configuration, camp_year: camp.camp_year - 1)

      described_class.all.each do |report_class|
        rows = report_class.new(other_camp).rows
        if report_class == Admin::Reports::RegisteredButNotApplied
          # Nobody applied for the other year, so every registered user is listed.
          expect(rows.map { |row| row[1] }).to include('lurker@example.com', fixtures.complete.user.email)
        else
          expect(rows).to eq([]), "#{report_class.key} leaked rows from another camp year"
        end
      end
    end

    it 'renders the country column as "Name - CODE"' do
      rows = Admin::Reports::EnrolledWithAddresses.new(camp).rows

      expect(rows.map(&:first)).to contain_exactly('United States of America - US', 'Russian Federation - RU')
    end

    it 'blanks repeated session and course cells on the class list' do
      rows = Admin::Reports::CourseAssignments.new(camp).rows

      expect(rows.map { |row| row.first(2) })
        .to eq([['Session A', 'Number Theory'], ['', 'Topology'], ['Session B', 'Statistics']])
    end

    it 'computes the balance due like PaymentState and formats it as money' do
      row = Admin::Reports::OfferAcceptedWithBalanceDue.new(camp).rows.sole

      expect(row.first).to eq('Emmy Noether')
      expect(row.last).to eq(Money.new(PaymentState.new(fixtures.accepted).balance_due, 'USD'))
      expect(row.last).to eq(Money.new(110_000, 'USD'))
    end

    it 'treats a negative (refund) payment as signed cents, like PaymentState' do
      # Payment now refuses negative amounts (#258); legacy rows can still hold them.
      refund = build(:payment, user: fixtures.accepted.user, total_amount: '-20000', transaction_status: '1',
                               camp_year: camp.camp_year)
      refund.save!(validate: false)

      row = Admin::Reports::OfferAcceptedWithBalanceDue.new(camp).rows.sole

      expect(row.last).to eq(Money.new(PaymentState.new(fixtures.accepted).balance_due, 'USD'))
      expect(row.last).to eq(Money.new(130_000, 'USD'))
    end

    it 'formats the financial aid amount as money' do
      csv = CSV.parse(Admin::Reports::AllCompleteApps.new(camp).to_csv)
      amount = csv[2].index('FIN AID AMOUNT')

      expect(csv.drop(3).map { |row| row[amount] }).to contain_exactly('$1,234.50', nil)
    end
  end
end
