# frozen_string_literal: true

ActiveAdmin.register NelnetCallbackLog do
  menu parent: 'Applicant Info', priority: 5

  actions :index, :show

  filter :transaction_id
  filter :order_number
  filter :transaction_status, as: :select
  filter :created_at

  index do
    column :id
    column :transaction_id
    column :order_number
    column :transaction_status
    column 'Total amount' do |log|
      log.transaction_total_amount.present? ? number_to_currency(log.transaction_total_amount.to_i / 100.0) : '—'
    end
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :transaction_id
      row :order_number
      row :transaction_status
      row :transaction_total_amount
      row :created_at
      row 'Raw params (JSON)' do |log|
        pre { log.raw_params }
      end
    end
  end
end
