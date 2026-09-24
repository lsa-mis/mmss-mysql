# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::BalanceDueQuery do
  let(:camp) { CampConfiguration.active.first }
  let(:session) { CampOccurrence.active.no_any_session.first }

  # Payment#set_status moves an application back to `submitted` on its first successful payment,
  # so payments are recorded first and the status is pinned afterwards.
  def accepted_enrollment(payments: [])
    user = create(:user, :with_applicant_detail)
    enrollment = create(:enrollment, :accepted, user: user)
    create(:session_assignment, :accepted, enrollment: enrollment, camp_occurrence: session)
    payments.each { |attrs| create(:payment, user: user, camp_year: enrollment.campyear, **attrs) }
    enrollment.update_columns(application_status: 'offer accepted', offer_status: 'accepted')
    enrollment
  end

  before { create(:enrollment) } # ensures camp/session/course seed data exists

  it 'matches PaymentState#balance_due, including activities, awarded aid and successful payments' do
    enrollment = accepted_enrollment(payments: [{ total_amount: '3000', transaction_status: '1' },
                                                { total_amount: '9999', transaction_status: '2' }])
    activity = create(:activity, camp_occurrence: session, cost_cents: 2_500)
    create(:enrollment_activity, enrollment: enrollment, activity: activity)
    create(:financial_aid, enrollment: enrollment, status: 'awarded', amount_cents: 1_000)

    query = described_class.new(camp)
    row = query.enrollments(limit: 20).first

    expect(row).to eq(enrollment)
    expect(row.balance_due_cents.to_i).to eq(PaymentState.new(enrollment).balance_due)
    expect(row.balance_due_cents.to_i).to eq(session.cost_cents + 2_500 + camp.application_fee_cents - 1_000 - 3_000)
    expect(query.count).to eq(1)
  end

  it 'excludes fully paid applications, other statuses and other camp years' do
    owing = accepted_enrollment
    paid = accepted_enrollment(payments: [{ transaction_status: '1', total_amount: (session.cost_cents + camp.application_fee_cents).to_s }])
    expect(PaymentState.new(paid).balance_due).to eq(0)
    create(:enrollment, :enrolled, user: create(:user, :with_applicant_detail))

    query = described_class.new(camp)

    expect(query.enrollments(limit: 20)).to eq([owing])
    expect(query.count).to eq(1)
  end

  it 'orders by applicant name and honours the limit' do
    first = accepted_enrollment
    second = accepted_enrollment
    first.applicant_detail.update!(lastname: 'Zed')
    second.applicant_detail.update!(lastname: 'Abel')

    query = described_class.new(camp)

    expect(query.enrollments(limit: 20)).to eq([second, first])
    expect(query.enrollments(limit: 1)).to eq([second])
    expect(query.count).to eq(2)
  end

  it 'is empty without an active camp' do
    query = described_class.new(nil)

    expect(query.enrollments(limit: 20)).to eq([])
    expect(query.count).to eq(0)
  end
end
