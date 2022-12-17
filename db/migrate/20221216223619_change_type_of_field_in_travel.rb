class ChangeTypeOfFieldInTravel < ActiveRecord::Migration[6.1]
  def change
    change_column :travels, :depart_route_num, :string
  end
end
