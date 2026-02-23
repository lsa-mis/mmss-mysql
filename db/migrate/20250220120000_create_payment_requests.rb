# frozen_string_literal: true

class CreatePaymentRequests < ActiveRecord::Migration[6.1]
  def change
    create_table :payment_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.string :order_number, null: false, comment: 'Sent to Nelnet as orderNumber (user_account)'
      t.integer :amount_cents, null: false, comment: 'Amount sent in request (cents)'
      t.integer :camp_year
      t.bigint :request_timestamp, null: false, comment: 'Epoch timestamp sent in URL to Nelnet'
      t.references :payment, null: true, foreign_key: true, comment: 'Set when receipt received'

      t.timestamps
    end

    add_index :payment_requests, [:user_id, :order_number]
  end
end
