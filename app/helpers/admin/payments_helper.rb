# frozen_string_literal: true

module Admin::PaymentsHelper
  # "Lastname, Firstname" of the paying user (falls back to the email) with the email underneath.
  def admin_payment_user(payment)
    user = payment.user
    name = user.applicant_detail&.full_name || user.email
    safe_join([tag.span(name, class: 'font-medium'), tag.div(user.email, class: 'text-xs text-slate-500')])
  end

  # Nelnet status code with its meaning: "1" is the only successful status.
  def admin_payment_status_badge(status)
    return admin_empty_value if status.blank?

    colour = status.to_s == '1' ? 'green' : 'red'
    tag.span("#{status} · #{transaction_status_message(status)}", class: "admin-badge-#{colour}",
                                                                  title: transaction_status_message(status))
  end

  # Applicant picker for a new manual payment: current-camp applications keyed by user id. The
  # payer cannot be changed after creation, so the picker only appears on `new`; a user chosen
  # on a failed submit stays selectable even when they have no current-camp application.
  def admin_payment_user_options(payment)
    options = Admin::EnrollmentOptions.current_camp_users
    if payment.user && options.none? { |_label, id| id == payment.user_id }
      options << [payment.user.email, payment.user_id]
    end
    options
  end
end
