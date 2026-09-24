# frozen_string_literal: true

# ActiveAdmin had filters disabled here; these are additive.
class Admin::RecuploadsFilter < Admin::Filter
  text :studentname, label: 'Student name'
  text :authorname, label: 'Author / recommender'
  date_range :created_at, label: 'Uploaded'
end
