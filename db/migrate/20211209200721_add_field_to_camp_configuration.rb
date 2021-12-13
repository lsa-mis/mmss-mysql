class AddFieldToCampConfiguration < ActiveRecord::Migration[6.1]
  def change
    add_column :camp_configurations, :application_fee_required, :boolean
  end
end
