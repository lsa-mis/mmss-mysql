# frozen_string_literal: true

ActiveAdmin.register PaymentRequest do
  menu parent: 'Applicant Info', priority: 4

  actions :index, :show

  filter :user_id, as: :select, collection: -> { User.all.order(:email) }
  filter :order_number
  filter :camp_year, as: :select
  filter :payment_id, label: 'Matched payment', as: :select, collection: -> { Payment.order(created_at: :desc).limit(500).map { |p| ["#{p.transaction_id} (#{p.created_at.strftime('%Y-%m-%d %H:%M')})", p.id] } }
  filter :created_at

  index do
    column :id
    column 'User' do |pr|
      pr.user&.email
    end
    column :order_number
    column 'Amount' do |pr|
      number_to_currency(pr.amount_cents / 100.0)
    end
    column :camp_year
    column 'Request timestamp' do |pr|
      pr.request_timestamp.present? ? Time.zone.at(pr.request_timestamp / 1000).strftime('%Y-%m-%d %H:%M') : nil
    end
    column 'Matched payment' do |pr|
      if pr.payment_id?
        link_to "Payment ##{pr.payment_id}", admin_payment_path(pr.payment)
      else
        status_tag('Unmatched', class: 'no')
      end
    end
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :user do |pr|
        pr.user&.email
      end
      row :order_number
      row 'Amount (cents)' do |pr|
        pr.amount_cents
      end
      row 'Amount' do |pr|
        number_to_currency(pr.amount_cents / 100.0)
      end
      row :camp_year
      row 'Request timestamp (epoch ms)' do |pr|
        pr.request_timestamp
      end
      row 'Request time' do |pr|
        pr.request_timestamp.present? ? Time.zone.at(pr.request_timestamp / 1000) : nil
      end
      row :payment do |pr|
        if pr.payment_id?
          link_to "Payment ##{pr.payment_id}", admin_payment_path(pr.payment)
        else
          '—'
        end
      end
      row :created_at
      row :updated_at
    end
  end

  # Scopes for quick filters
  scope :all, default: true
  scope :unmatched do |scope|
    scope.where(payment_id: nil)
  end
end
