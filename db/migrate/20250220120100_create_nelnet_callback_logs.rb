# frozen_string_literal: true

class CreateNelnetCallbackLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :nelnet_callback_logs do |t|
      t.string :transaction_id, comment: 'Nelnet transactionId from callback'
      t.string :order_number, comment: 'orderNumber from callback (user_account)'
      t.string :transaction_status
      t.string :transaction_total_amount
      t.text :raw_params, comment: 'Full request params as JSON'

      t.timestamps
    end

    add_index :nelnet_callback_logs, :transaction_id
    add_index :nelnet_callback_logs, :order_number
    add_index :nelnet_callback_logs, :created_at
  end
end
