module FinancialAidsHelper
  def financial_aid_status
    [
      ['pending', 'pending'],
      ['awarded', 'awarded'],
      ['rejected', 'rejected'],
    ]
  end

  def fin_aid_pending
    FinancialAid.where(enrollment_id: Enrollment.current_camp_year_applications, status: "pending")
  end
end
