class AddWaitListToCourseAssignment < ActiveRecord::Migration[6.1]
  def change
    add_column :course_assignments, :wait_list, :boolean, default: false
  end
end
