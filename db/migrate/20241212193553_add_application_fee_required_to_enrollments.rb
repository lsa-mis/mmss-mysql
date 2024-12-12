class AddApplicationFeeRequiredToEnrollments < ActiveRecord::Migration[6.1]
  def change
    add_column :enrollments, :application_fee_required, :boolean, default: true, null: false
  end
end
