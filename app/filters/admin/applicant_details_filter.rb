# frozen_string_literal: true

# Index filters for Admin::ApplicantDetailsController. `lastname` is a starts-with
# text field (the legacy admin offered a select over every distinct last name).
class Admin::ApplicantDetailsFilter < Admin::Filter
  select :gender, collection: -> { Gender.order(:name).pluck(:name, :id).map { |name, id| [name, id.to_s] } }
  select :demographic_id, label: 'Demographic', collection: -> { Demographic.order(:name).pluck(:name, :id) }
  text :lastname, label: 'Last name (starts with)', match: :starts_with
  boolean :us_citizen
  date_range :birthdate
  text :diet_restrictions
  text :parentname, label: 'Parent name'
end
