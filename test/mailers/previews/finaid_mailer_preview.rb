class FinaidMailerPreview < ActionMailer::Preview
  def fin_aid_awarded_email
    finaid = FinancialAid.first || create_test_finaid
    balance_due = 233500
    FinaidMailer.fin_aid_awarded_email(finaid, balance_due)
  end

  def fin_aid_rejected_email
    finaid = FinancialAid.first || create_test_finaid
    balance_due = 200000
    FinaidMailer.fin_aid_rejected_email(finaid, balance_due)
  end

  def fin_aid_request_email
    enrollment = Enrollment.first
    FinaidMailer.with(enrollment: enrollment.id).fin_aid_request_email
  end

  private

  def create_test_finaid
    enrollment = Enrollment.first || create_test_enrollment
    FinancialAid.create!(
      enrollment: enrollment,
      amount_cents: 50000, # $500.00
      source: "Test Source",
      note: "Test financial aid",
      status: "awarded",
      payments_deadline: Date.today + 30.days
    )
  end

  def create_test_enrollment
    user = User.first || create_test_user
    Enrollment.create!(
      user: user,
      campyear: Time.now.year,
      application_status: "submitted"
    )
  end

  def create_test_user
    User.create!(
      email: "test@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end
end
