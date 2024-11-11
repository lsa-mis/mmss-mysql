class ChangeDemographicColumnType < ActiveRecord::Migration[6.1]
  def up
    return if column_exists?(:applicant_details, :demographic_id)

    # Create new column if old one exists
    if column_exists?(:applicant_details, :demographic)
      change_column_null :applicant_details, :demographic, true
      add_column :applicant_details, :demographic_id, :bigint

      execute <<-SQL
        UPDATE applicant_details#{' '}
        SET demographic_id = CAST(demographic AS UNSIGNED)#{' '}
        WHERE demographic IS NOT NULL AND demographic != '';
      SQL

      remove_column :applicant_details, :demographic
    else
      add_column :applicant_details, :demographic_id, :bigint
    end

    add_foreign_key :applicant_details, :demographics
    add_index :applicant_details, :demographic_id
  end

  def down
    remove_foreign_key :applicant_details, :demographics
    remove_index :applicant_details, :demographic_id

    add_column :applicant_details, :demographic, :string

    execute <<-SQL
      UPDATE applicant_details#{' '}
      SET demographic = demographic_id::varchar#{' '}
      WHERE demographic_id IS NOT NULL;
    SQL

    remove_column :applicant_details, :demographic_id
  end
end
