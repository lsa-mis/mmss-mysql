class AddIndexToEnrollment < ActiveRecord::Migration[6.1]
  def change
    add_index :enrollments, [:user_id, :campyear], unique: true
  end
end
