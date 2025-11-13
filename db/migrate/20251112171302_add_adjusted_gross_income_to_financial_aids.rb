class AddAdjustedGrossIncomeToFinancialAids < ActiveRecord::Migration[6.1]
  def change
    add_column :financial_aids, :adjusted_gross_income, :integer
  end
end
