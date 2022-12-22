class AddFieldsToTravel < ActiveRecord::Migration[6.1]
  def change
    rename_column :travels, :transport_needed, :arrival_transport
    rename_column :travels, :carrier, :arrival_carrier
    rename_column :travels, :route_num, :arrival_route_num
    add_column :travels, :arrival_date, :date
    add_column :travels, :arrival_time, :time
    add_column :travels, :depart_transport, :string
    add_column :travels, :depart_route_num, :string
    add_column :travels, :depart_date, :date
    add_column :travels, :depart_time, :time
    add_column :travels, :depart_carrier, :string
    add_column :travels, :arrival_session, :string
    add_column :travels, :depart_session, :string
  end
end
