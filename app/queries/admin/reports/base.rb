# frozen_string_literal: true

# One CSV report: a fixed SQL statement, bound to the selected camp, rendered through
# Admin::CsvExport.report (title row, total-count row, upper-cased headers, formula guard).
#
#   class Admin::Reports::AllCompleteApps < Admin::Reports::Base
#     self.label = 'All Complete Applications'          # index page + legacy link text
#     self.description = 'Every application ...'
#     self.csv_title = 'all_complete_applications'      # CSV title row and filename (legacy names kept)
#     self.sql = <<~SQL
#       SELECT ... WHERE e.campyear = :camp_year
#     SQL
#   end
#
# The only values that ever reach the SQL are `:camp_year` and `:camp_id` of a CampConfiguration
# row chosen by the controller; they are bound with sanitize_sql_array, never interpolated.
# Row transforms (country names, blanked repeats, cents → Money) override #transform_row or #rows.
class Admin::Reports::Base
  class_attribute :label, :description, :csv_title, :sql, instance_writer: false

  # URL segment and registry key, e.g. Admin::Reports::AllCompleteApps → "all_complete_apps".
  def self.key = name.demodulize.underscore

  # Parameters the report takes (shown on the index page). Every report is bound to one camp year.
  def self.parameters = [:camp_year]

  attr_reader :camp

  def initialize(camp)
    @camp = camp
  end

  def key = self.class.key

  def result
    @result ||= ActiveRecord::Base.connection.exec_query(bound_sql, "Admin::Reports::#{self.class.name.demodulize}")
  end

  def rows = result.rows.map { |row| transform_row(row.dup) }

  def headers = nil

  def to_csv
    Admin::CsvExport.report(ActiveRecord::Result.new(result.columns, rows), title: csv_title, headers: headers)
  end

  def filename = Admin::CsvExport.filename("report-#{csv_title}")

  def bound_sql
    ActiveRecord::Base.sanitize_sql_array([sql, { camp_year: Integer(camp.camp_year), camp_id: Integer(camp.id) }])
  end

  private

  def transform_row(row) = row

  def column_index(name) = result.columns.index(name.to_s)

  def money(cents) = Money.new(cents.to_i, 'USD')

  # "United States of America - US" for ISO codes the countries gem knows; the raw value otherwise.
  def country_name(code)
    return code if code.blank?

    country = ISO3166::Country[code]
    country ? "#{country.name} - #{code}" : code
  end
end
