class CreatePaymentArchives < ActiveRecord::Migration[6.1]
  def change
    create_table :payment_archives do |t|
        t.string :transaction_type
        t.string :transaction_status
        t.string :transaction_id
        t.string :total_amount
        t.string :transaction_date
        t.string :account_type
        t.string :result_code
        t.string :result_message
        t.string :user_account
        t.string :payer_identity
        t.string :timestamp
        t.string :transaction_hash
        t.integer :camp_year
        t.string :user_email
        t.string :first_name
        t.string :last_name
      t.timestamps
    end
  end
end
