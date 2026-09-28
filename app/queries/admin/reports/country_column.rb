# frozen_string_literal: true

# Reports whose first column is the applicant's ISO country code render it as "Name - CODE"
# (the legacy `with_country` / `demographic` CSV formatters).
module Admin::Reports::CountryColumn
  private

  def transform_row(row)
    row[0] = country_name(row[0])
    row
  end
end
