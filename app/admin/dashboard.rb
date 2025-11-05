# frozen_string_literal: true

ActiveAdmin.register_page 'Dashboard' do
  menu priority: 1, label: proc { I18n.t('active_admin.dashboard') }

  content title: proc { I18n.t('active_admin.dashboard') } do
    columns do
      if CampConfiguration.active.present?
        column do
          panel link_to("Recent Applications for #{current_camp_year} Camp", admin_applications_path) do
            if Enrollment.current_camp_year_applications.any?
              ul do
                Enrollment.current_camp_year_applications.order(created_at: :desc).limit(10).map do |enroll|
                  li link_to(enroll.applicant_detail.full_name + ', ' + enroll.user.email,
                             admin_application_path(enroll))
                end
              end
            end
          end

          panel link_to("Recent Payments for #{current_camp_year} Camp", admin_payments_path) do
            if Payment.current_camp_payments.any?
              ul do
                Payment.current_camp_payments.order(created_at: :desc).limit(10).map do |payment|
                  li link_to(
                    "#{payment.user.applicant_detail.full_name_and_email} - #{humanized_money_with_symbol(payment.total_amount.to_f / 100)}", admin_payment_path(payment.id)
                  )
                end
              end
            end
          end

          panel link_to("Offer Accepted with Balance Due", admin_reports_offer_accepted_with_balance_due_path) do
            offer_accepted_enrollments = Enrollment.current_camp_year_applications.where(application_status: 'offer accepted')
              .includes(:user, :applicant_detail)
              .order('applicant_details.lastname, applicant_details.firstname')

            enrollments_with_balance = offer_accepted_enrollments.select do |enroll|
              payment_state = PaymentState.new(enroll)
              payment_state.balance_due > 0
            end

            if enrollments_with_balance.any?
              ul do
                enrollments_with_balance.first(20).map do |enroll|
                  payment_state = PaymentState.new(enroll)
                  balance_due = payment_state.balance_due
                  applicant_detail = enroll.applicant_detail
                  birthdate_str = applicant_detail.birthdate.strftime('%Y-%m-%d')

                  li do
                    link_to(
                      "#{applicant_detail.full_name} - DOB: #{birthdate_str} - Parent: #{applicant_detail.parentname} - Balance: #{humanized_money_with_symbol(balance_due / 100)}",
                      admin_application_path(enroll)
                    )
                  end
                end
              end

              if enrollments_with_balance.count > 20
                div do
                  text_node link_to("View full report (#{enrollments_with_balance.count} total)...", admin_reports_offer_accepted_with_balance_due_path)
                end
              end
            else
              text_node "No offer accepted applications with balance due"
            end
          end

          panel link_to('Financial Aid Requests', admin_financial_aid_requests_path) do
            div do
              render('/admin/pending_finaid_requests', model: 'dashboard')
            end
          end
        end

        column do
          panel 'Session Stats' do
            div do
              render('/admin/session_enrolled', model: 'dashboard')
            end

            hr

            div do
              render('/admin/session_assigned', model: 'dashboard')
            end

            hr

            div do
              render('/admin/session_applied', model: 'dashboard')
            end
          end

          panel 'Active Camp Note' do
            div do
              render('/admin/dashboard_camp_note', model: 'dashboard')
            end
          end
          panel 'Resources' do
            ul do
              li link_to('Admin Documentation',
                         'https://docs.google.com/document/d/17M9433ybPpvyXc_RwsnydfmSQsWN80Iwg2t0ACItoKo/edit?usp=sharing', target: '_blank')
            end
          end
        end
      else
        panel 'Notifications' do
          'No active camps'
        end
      end
    end
  end
end
