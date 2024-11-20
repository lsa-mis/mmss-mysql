class AddCampDocFormCompletedToEnrollment < ActiveRecord::Migration[6.1]
  def change
    add_column :enrollments, :camp_doc_form_completed, :boolean, default: false
  end
end
