# frozen_string_literal: true

# CSV downloads for admin index pages. Declare the columns with Admin::CsvExport and send them:
#
#   CSV_COLUMNS = Admin::CsvExport.define do
#     column :updated_at
#     column('Name') { |app| app.applicant_detail.full_name }
#   end
#
#   respond_to do |format|
#     format.html
#     format.csv { send_csv(CSV_COLUMNS, records, filename: 'applications') }
#   end
module Admin::CsvExportable
  extend ActiveSupport::Concern

  def send_csv(export, records, filename:)
    send_data export.generate(records),
              type: 'text/csv; charset=utf-8',
              disposition: 'attachment',
              filename: Admin::CsvExport.filename(filename)
  end
end
