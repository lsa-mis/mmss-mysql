# frozen_string_literal: true

# Payment has validated transaction_id uniqueness since 2019 (fd1127f), but no migration ever backed
# it with a database index, so two concurrent Nelnet receipts for the same transactionId could both
# pass validation (PaymentsController#payment_receipt does find_by then create). Some local databases
# already carry this index, added by hand; the guards keep the migration a no-op there.
#
# Before running against production, check for duplicates, which would make add_index fail:
#   SELECT transaction_id, COUNT(*) FROM payments GROUP BY transaction_id HAVING COUNT(*) > 1;
class AddUniqueIndexToPaymentsTransactionId < ActiveRecord::Migration[8.1]
  def up
    return if index_exists?(:payments, :transaction_id, unique: true)

    add_index :payments, :transaction_id, unique: true
  end

  def down
    remove_index :payments, :transaction_id if index_exists?(:payments, :transaction_id)
  end
end
