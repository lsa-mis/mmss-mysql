# frozen_string_literal: true

require 'csv'

# CSV output for the admin.
#
# 1. Per-resource column sets (the ActiveAdmin `csv do ... end` block equivalent):
#
#      EXPORT = Admin::CsvExport.define do
#        column :updated_at
#        column('Name') { |app| app.applicant_detail.full_name }
#        column :offer_status, header: 'Offer'
#      end
#
#      EXPORT.generate(records) # => CSV string, header row first
#
# 2. Raw-SQL reports (Admin::Reports::*): a title row, a total-count row, upper-cased titleized
#    headers and one row per result, with an optional per-row transform. Cells are formatted like
#    the column exports (Money → "$1,234.50", dates → ISO 8601) and strings go through the
#    formula guard.
#
#      Admin::CsvExport.report(ActiveRecord::Base.connection.exec_query(sql), title: 'all_complete_apps')
#      Admin::CsvExport.report(result, title: 'enrolled_with_addresses') { |row| row.map { |v| ... } }
class Admin::CsvExport
  Column = Struct.new(:header, :block)

  def self.define(&block)
    new.tap { |export| export.instance_eval(&block) }
  end

  def self.filename(base)
    "MMSS-#{base.to_s.parameterize}-#{Date.current.strftime('%-b-%-d-%Y')}.csv"
  end

  # `result` is anything responding to #columns and #rows (ActiveRecord::Result) or a Hash-like
  # `{ columns:, rows: }`. `headers:` overrides the column headers when the SQL aliases are not
  # presentable (e.g. `BALANCE DUE` computed from cents).
  def self.report(result, title:, headers: nil, total_row: true)
    columns = headers || result.columns.map { |column| column.to_s.titleize.upcase }
    rows = result.rows

    CSV.generate(headers: false) do |csv|
      csv << [title.to_s.titleize]
      csv << ["Total number of records: #{rows.size}"] if total_row
      csv << columns
      rows.each { |row| csv << (block_given? ? yield(row) : row).map { |cell| format_cell(cell) } }
    end
  end

  # One cell of CSV output. Non-string values are rendered by us (so they never need the formula
  # guard): times/dates in ISO order, Money with its symbol, BigDecimal in plain notation (its
  # `to_s` is scientific: `0.12345e3`).
  def self.format_cell(value)
    case value
    when nil then nil
    when ActiveSupport::TimeWithZone, Time, DateTime then value.strftime('%Y-%m-%d %H:%M:%S')
    when Date then value.iso8601
    when Money then value.format
    when BigDecimal then value.to_s('F')
    when Numeric, true, false then value.to_s
    else sanitize_cell(value.to_s)
    end
  end

  # Spreadsheet formula injection guard. Excel/LibreOffice/Sheets evaluate cells that start with
  # `=`, `+`, `-` or `@` (and treat a leading tab/CR as a control prefix), so a user-supplied value
  # such as `=HYPERLINK(...)` in a feedback message, name or note would execute when an admin opens
  # the export. Such strings are prefixed with a single quote, the spreadsheet convention for
  # "this is text" (the quote is not displayed in the cell). Only strings are touched: numbers,
  # dates, booleans and Money are formatted by the exporter itself, so a negative balance
  # (`-$25.00`) is never mangled.
  FORMULA_PREFIX = /\A[=+\-@\t\r]/

  def self.sanitize_cell(value)
    value.is_a?(String) && value.match?(FORMULA_PREFIX) ? "'#{value}" : value
  end

  def initialize
    @columns = []
  end

  attr_reader :columns

  def column(name, header: nil, &block)
    header ||= name.is_a?(Symbol) ? name.to_s.humanize : name.to_s
    block ||= ->(record) { record.public_send(name) }
    @columns << Column.new(header, block)
    self
  end

  def headers = columns.map(&:header)

  def generate(records)
    CSV.generate(headers: false) do |csv|
      csv << headers
      records.each do |record|
        csv << columns.map { |column| self.class.format_cell(column.block.call(record)) }
      end
    end
  end
end
