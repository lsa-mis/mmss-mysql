class AddUniqnameToEnrollment < ActiveRecord::Migration[6.1]
  def change
    add_column :enrollments, :uniqname, :string
  end
end
