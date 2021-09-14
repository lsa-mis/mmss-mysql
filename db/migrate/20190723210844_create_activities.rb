class CreateActivities < ActiveRecord::Migration[6.0]
  def change
    create_table :activities do |t|
      t.references :camp_occurrence, foreign_key: true
      t.string :description
      t.integer :cost_cents
      t.date :date_occurs
      t.boolean :active, default: false

      t.timestamps
    end
  end
end
