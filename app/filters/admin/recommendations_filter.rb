# frozen_string_literal: true

# Index filters for Admin::RecommendationsController (the legacy admin had none here). The applicant name filter relies on
# the controller's base relation joining applicant_details.
class Admin::RecommendationsFilter < Admin::Filter
  text :applicant_lastname, label: 'Applicant Last Name (Starts with)', match: :starts_with, column: 'applicant_details.lastname'
  text :lastname, label: 'Recommender Last Name'
  text :email, label: 'Recommender Email'
  text :organization
end
