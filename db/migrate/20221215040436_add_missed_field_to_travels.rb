class AddMissedFieldToTravels < ActiveRecord::Migration[6.1]
  def change
    add_column :travels, :depart_carrier, :string
  end
end
