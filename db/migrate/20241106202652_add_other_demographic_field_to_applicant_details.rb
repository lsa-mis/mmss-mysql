class AddOtherDemographicFieldToApplicantDetails < ActiveRecord::Migration[6.1]
  def change
    add_column :applicant_details, :demographic_other, :string
  end
end
