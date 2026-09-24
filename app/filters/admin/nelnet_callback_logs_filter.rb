# frozen_string_literal: true

class Admin::NelnetCallbackLogsFilter < Admin::Filter
  text :transaction_id
  text :order_number
  select :transaction_status, collection: -> { NelnetCallbackLog.where.not(transaction_status: [nil, '']).distinct.order(:transaction_status).pluck(:transaction_status) }
  date_range :created_at
end
