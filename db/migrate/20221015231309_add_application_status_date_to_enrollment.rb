class AddApplicationStatusDateToEnrollment < ActiveRecord::Migration[6.1]
  def change
    add_column :enrollments, :application_status_updated_on, :date
  end
end
