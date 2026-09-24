# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::Filter do
  let(:filter_class) do
    Class.new(Admin::Filter) do
      text :description, match: :starts_with
      text :note, match: :contains, column: 'description'
      select :status, collection: %w[open closed], column: 'status'
      boolean :active
      date_range :date_occurs
      date_range :created_at
      number :cost_cents
    end
  end

  let(:session) { create(:camp_occurrence) }

  def apply(params)
    filter_class.new(ActionController::Parameters.new(params)).apply(Activity.all)
  end

  it 'declares fields with labels and permitted params' do
    expect(filter_class.fields.map(&:name)).to eq(%i[description note status active date_occurs created_at cost_cents])
    expect(filter_class.fields.first.label).to eq('Description')
    expect(filter_class.new({}).permitted_params).to include('date_occurs_from', 'date_occurs_to', 'active')
  end

  it 'ignores unknown, blank and non-declared params' do
    filter = filter_class.new(ActionController::Parameters.new(description: ' ', bogus: 'x', status: 'open'))

    expect(filter.values).to eq('status' => 'open')
    expect(filter).to be_active
    expect(filter.to_params).to eq(q: { 'status' => 'open' })
    expect(filter_class.new(nil)).not_to be_active
  end

  it 'filters text with starts_with and contains, escaping LIKE wildcards' do
    dorm = create(:activity, camp_occurrence: session, description: 'Dormitory (Residential Stay)')
    create(:activity, camp_occurrence: session, description: 'Airport Shuttle - departure')
    create(:activity, camp_occurrence: session, description: '100% Fun')

    expect(apply(description: 'Dorm')).to contain_exactly(dorm)
    expect(apply(note: 'Residential')).to contain_exactly(dorm)
    expect(apply(description: '100%').map(&:description)).to eq(['100% Fun'])
  end

  it 'filters selects, booleans, numbers and date ranges' do
    cheap = create(:activity, camp_occurrence: session, cost_cents: 1000, active: true, date_occurs: Date.new(2030, 7, 1))
    dear = create(:activity, camp_occurrence: session, cost_cents: 9000, active: false, date_occurs: Date.new(2030, 8, 1))

    expect(apply(active: 'true')).to contain_exactly(cheap)
    expect(apply(active: 'false')).to contain_exactly(dear)
    expect(apply(cost_cents: '9000')).to contain_exactly(dear)
    expect(apply(date_occurs_from: '2030-07-15')).to contain_exactly(dear)
    expect(apply(date_occurs_to: '2030-07-15')).to contain_exactly(cheap)
    expect(apply(date_occurs_from: '2030-06-01', date_occurs_to: '2030-07-15')).to contain_exactly(cheap)
    expect(apply(date_occurs_from: 'not a date')).to contain_exactly(cheap, dear)
  end

  it 'treats datetime columns as whole days' do
    activity = create(:activity, camp_occurrence: session)
    today = activity.created_at.to_date.iso8601

    expect(apply(created_at_from: today, created_at_to: today)).to contain_exactly(activity)
  end

  it 'joins associations when asked' do
    joined = Class.new(Admin::Filter) do
      text :session, match: :starts_with, column: 'camp_occurrences.description', joins: :camp_occurrence
    end
    other_session = create(:camp_occurrence, camp_configuration: session.camp_configuration, description: 'Zeta Session')
    match = create(:activity, camp_occurrence: other_session)
    create(:activity, camp_occurrence: session)

    expect(joined.new(session: 'Zeta').apply(Activity.all)).to contain_exactly(match)
  end
end
