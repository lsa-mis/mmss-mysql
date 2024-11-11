class AddProtectedToDemographics < ActiveRecord::Migration[6.1]
  def change
    add_column :demographics, :protected, :boolean, default: false

    reversible do |dir|
      dir.up do
        Demographic.reset_column_information
        if other = Demographic.find_by(name: 'Other')
          other.update_column(:protected, true)
        else
          Demographic.create!(name: 'Other', description: 'Other demographic option', protected: true)
        end
      end
    end
  end
end
