class AddApplicationFeeRequiredToCampConfigurations < ActiveRecord::Migration[6.1]
  def change
    add_column :camp_configurations, :application_fee_required, :boolean, default: true, null: false
  end
end
