class AddFacultyToCourses < ActiveRecord::Migration[6.1]
  def change
    add_column :courses, :faculty_uniqname, :string
    add_column :courses, :faculty_name, :string
  end
end
