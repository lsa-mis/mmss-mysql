# frozen_string_literal: true

# CSV reports (the ActiveAdmin "Reports" page). The index lists every registered report; `show`
# streams one as CSV. The only inputs are the report key (looked up in Admin::Reports, never used
# to build SQL) and an optional camp year, which must match a CampConfiguration row; anything else
# is rejected with a redirect back to the index.
class Admin::ReportsController < Admin::BaseController
  CAMP_YEAR_FORMAT = /\A\d{4}\z/

  rescue_from ActiveRecord::RecordNotFound, with: :report_not_found

  before_action :set_camp

  def index
    @groups = Admin::Reports::GROUPS
    @camp_years = CampConfiguration.order(camp_year: :desc).pluck(:camp_year)
  end

  def show
    report_class = Admin::Reports.find(params[:id]) or raise ActiveRecord::RecordNotFound
    raise ActiveRecord::RecordNotFound unless @camp

    report = report_class.new(@camp)
    send_data report.to_csv, type: 'text/csv; charset=utf-8', disposition: 'attachment', filename: report.filename
  end

  private

  # The selected camp: `?camp_year=YYYY` (must exist) or, when the parameter is absent or an
  # unselected form field (empty string), the active camp. Anything else is rejected.
  def set_camp
    camp_year = params[:camp_year]
    @camp = if camp_year.nil? || camp_year == ''
              CampConfiguration.active.last
            elsif camp_year.is_a?(String) && camp_year.match?(CAMP_YEAR_FORMAT)
              CampConfiguration.find_by!(camp_year: Integer(camp_year, 10))
            else
              raise ActiveRecord::RecordNotFound
            end
  end

  def report_not_found
    redirect_to admin_reports_path, alert: 'Unknown report or camp year.', status: :see_other
  end
end
