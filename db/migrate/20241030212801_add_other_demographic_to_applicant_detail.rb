class AddOtherDemographicToApplicantDetail < ActiveRecord::Migration[6.1]
  def change
    add_column :applicant_details, :other_demographic, :string
  end
end
