# frozen_string_literal: true

# Index filters for Admin::RecuploadsController (the legacy admin had none here).
class Admin::RecuploadsFilter < Admin::Filter
  text :studentname, label: "Student name"
  text :authorname, label: "Author / recommender"
  date_range :created_at, label: "Uploaded"
end
