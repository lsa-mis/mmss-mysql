class AddSessionsToTravel < ActiveRecord::Migration[6.1]
  def change
    add_column :travels, :arrival_session, :string
    add_column :travels, :depart_session, :string
  end
end
