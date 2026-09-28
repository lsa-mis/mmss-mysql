# frozen_string_literal: true

module Admin::FinancialAidRequestsHelper
  # Adjusted gross income as currency ("$52,000.00"); nil when not reported.
  def admin_agi(amount)
    return nil if amount.blank?

    number_to_currency(amount, unit: '$', separator: '.', delimiter: ',')
  end

  # pending / awarded / rejected, plus whatever the record already holds so the select never
  # submits blank for a legacy value.
  def admin_financial_aid_status_options(financial_aid)
    options = Admin::FinancialAidRequestsController::STATUS_OPTIONS.dup
    current = financial_aid.status
    options << current if current.present? && options.exclude?(current)
    options
  end

  # Applicant name linking to the application's admin page, with the email underneath.
  def admin_financial_aid_applicant(enrollment, with_email: true)
    return admin_empty_value if enrollment.nil?

    name = enrollment.applicant_detail&.full_name || enrollment.user.email
    link = link_to(name, admin_application_path(enrollment), class: 'font-medium')
    return link unless with_email

    safe_join([link, tag.div(enrollment.user.email, class: 'text-xs text-slate-500')])
  end
end
