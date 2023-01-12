class RemoveFieldsFromTravel < ActiveRecord::Migration[6.1]
  def change
    remove_column :travels, :direction
    remove_column :travels, :date
    remove_column :travels, :mode
  end
end
