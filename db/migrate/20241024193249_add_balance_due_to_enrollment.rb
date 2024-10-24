class AddBalanceDueToEnrollment < ActiveRecord::Migration[6.1]
  def change
    add_column :enrollments, :balance_due_cents, :integer
  end
end
