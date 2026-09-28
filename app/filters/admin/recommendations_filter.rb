# frozen_string_literal: true

# ActiveAdmin had filters disabled here; these are additive. The applicant name filter relies on
# the controller's base relation joining applicant_details.
class Admin::RecommendationsFilter < Admin::Filter
  text :applicant_lastname, label: 'Applicant Last Name (Starts with)', match: :starts_with, column: 'applicant_details.lastname'
  text :lastname, label: 'Recommender Last Name'
  text :email, label: 'Recommender Email'
  text :organization
end
