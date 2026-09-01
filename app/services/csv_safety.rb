# frozen_string_literal: true

# Prefix cells that would be interpreted as spreadsheet formulas when opened
# in Excel/LibreOffice/Google Sheets (CSV injection / formula injection).
# Spreadsheets strip a wide set of leading whitespace/controls before checking
# for = + - @, so those prefixes must not bypass neutralization.
module CsvSafety
  CSV_LEADING_IGNORABLE = /\A(?:\p{Space}|\p{Cf}|[\x00-\x08\x0E-\x1F])*/u
  CSV_FORMULA_TRIGGER = /\A[=+\-@]/

  module_function

  def cell(value)
    return value unless value.is_a?(String)

    significant = value.sub(CSV_LEADING_IGNORABLE, '')
    return value unless significant.match?(CSV_FORMULA_TRIGGER)

    "'#{value}"
  end

  def row(cells)
    Array(cells).map { |c| cell(c) }
  end
end
