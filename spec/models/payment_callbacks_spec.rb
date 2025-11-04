# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Payment callbacks', type: :model do
  let!(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year, application_fee_cents: 1000) }
  let(:user) { create(:user, :with_applicant_detail) }
  let!(:enrollment) { create(:enrollment, user: user, campyear: camp_config.camp_year) }

  before do
    CampConfiguration.update_all(active: false)
    camp_config.update(active: true)
    allow(CampConfiguration).to receive(:active_camp_year).and_return(camp_config.camp_year)
    allow(CampConfiguration).to receive(:active).and_return(CampConfiguration.where(id: camp_config.id))
  end

  def build_payment(attrs = {})
    build(:payment, { user: user, transaction_status: '1', camp_year: camp_config.camp_year }.merge(attrs))
  end

  it 'on first successful payment (fee required) sets status submitted and sends app_complete email when no recupload' do
    # Ensure fee required is true for current enrollment
    enrollment.update!(application_fee_required: true)

    expect(RegistrationMailer).to receive(:app_complete_email).with(user).and_return(double(deliver_now: true))

    payment = build_payment
    expect { payment.save! }.to change { Payment.count }.by(1)

    expect(enrollment.reload.application_status).to eq('submitted')
    expect(enrollment.application_status_updated_on).to eq(Date.today)
  end

  it 'on first successful payment + recupload sets application complete' do
    enrollment.update!(application_fee_required: true)
    # Create recommendation + recupload
    recommendation = create(:recommendation, enrollment: enrollment)
    create(:recupload, recommendation: recommendation)

    expect(RegistrationMailer).to receive(:app_complete_email).with(user).and_return(double(deliver_now: true))

    payment = build_payment
    payment.save!

    expect(enrollment.reload.application_status).to eq('application complete')
    expect(enrollment.application_status_updated_on).to eq(Date.today)
  end

  it 'does not change status on subsequent successful payments (until enrolled condition met)' do
    enrollment.update!(application_fee_required: true)
    create(:payment, user: user, transaction_status: '1', camp_year: camp_config.camp_year)
    expect(enrollment.reload.application_status).to be_in(['submitted', 'application complete'])

    expect {
      create(:payment, user: user, transaction_status: '1', camp_year: camp_config.camp_year)
    }.not_to change { enrollment.reload.application_status }
  end

  it 'sets enrolled when balance_due is 0 and camp_doc_form_completed is true' do
    # Ensure PaymentState balance uses a stable active camp and 0 balance
    allow_any_instance_of(PaymentState).to receive(:balance_due).and_return(0)
    enrollment.update!(camp_doc_form_completed: true)

    payment = build_payment
    # Also ensure Payment callback path sees zero due
    allow_any_instance_of(Payment).to receive(:balance_due).and_return(0)

    payment.save!
    expect(enrollment.reload.application_status).to eq('enrolled')
  end

  it 'enforces unique transaction_id' do
    tid = "TXN-#{SecureRandom.hex(4)}"
    create(:payment, user: user, transaction_id: tid, camp_year: camp_config.camp_year)
    dup = build(:payment, user: user, transaction_id: tid, camp_year: camp_config.camp_year)
    expect(dup).not_to be_valid
    expect(dup.errors[:transaction_id]).to be_present
  end
end
