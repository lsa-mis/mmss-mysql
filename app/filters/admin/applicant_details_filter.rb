# frozen_string_literal: true

# Index filters for Admin::ApplicantDetailsController. Same fields as ActiveAdmin; `lastname`
# was a select over every distinct last name there and is a starts-with text field here.
class Admin::ApplicantDetailsFilter < Admin::Filter
  select :gender, collection: -> { Gender.order(:name).pluck(:name, :id).map { |name, id| [name, id.to_s] } }
  select :demographic_id, label: 'Demographic', collection: -> { Demographic.order(:name).pluck(:name, :id) }
  text :lastname, label: 'Last name (starts with)', match: :starts_with
  boolean :us_citizen
  date_range :birthdate
  text :diet_restrictions
  text :parentname, label: 'Parent name'
end
