# frozen_string_literal: true

# Session Configurations = CampOccurrence records (the ActiveAdmin resource was registered
# `as: 'Session Configurations'`).
class Admin::SessionConfigurationsController < Admin::BaseController
  before_action :set_session_configuration, only: %i[show edit update destroy]

  SORTS = {
    camp_year: 'camp_configurations.camp_year',
    description: 'camp_occurrences.description',
    cost: 'camp_occurrences.cost_cents',
    begin_date: 'camp_occurrences.begin_date',
    end_date: 'camp_occurrences.end_date',
    active: 'camp_occurrences.active',
    created_at: 'camp_occurrences.created_at',
    updated_at: 'camp_occurrences.updated_at'
  }.freeze

  BATCH_ACTIONS = { destroy: 'Delete selected', toggle_active: 'Toggle active' }.freeze

  CSV_EXPORT = Admin::CsvExport.define do
    column :id
    column('Camp year') { |session| session.camp_configuration.camp_year }
    column :description
    column :cost
    column :begin_date
    column :end_date
    column :active
    column :created_at
    column :updated_at
  end

  def index
    @filter = Admin::SessionConfigurationsFilter.new(params[Admin::Filter::PARAM_KEY])
    relation = @filter.apply(CampOccurrence.joins(:camp_configuration).includes(:camp_configuration))
    relation = apply_sort(relation, allowed: SORTS, default: :begin_date, default_direction: :desc)

    respond_to do |format|
      format.html { @pagy, @session_configurations = paginate(relation) }
      format.csv { send_csv(CSV_EXPORT, relation, filename: 'session-configurations') }
    end
  end

  def show; end

  def new
    @session_configuration = CampOccurrence.new
  end

  def create
    @session_configuration = CampOccurrence.new(session_configuration_params)

    if @session_configuration.save
      redirect_to admin_session_configuration_path(@session_configuration), notice: 'Session configuration was successfully created.',
                                                                             status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @session_configuration.update(session_configuration_params)
      redirect_to admin_session_configuration_path(@session_configuration), notice: 'Session configuration was successfully updated.',
                                                                             status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @session_configuration.destroy
    redirect_to admin_session_configurations_path, notice: 'Session configuration was successfully deleted.', status: :see_other
  end

  def batch
    perform_batch_action(CampOccurrence.all, BATCH_ACTIONS, redirect_to_path: admin_session_configurations_path)
  end

  private

  def batch_toggle_active(records)
    toggled = records.to_a.count { |record| record.update(active: !record.active) }
    "Toggled active status for #{toggled} #{'session configuration'.pluralize(toggled)}."
  end

  def set_session_configuration
    @session_configuration = CampOccurrence.includes(:camp_configuration).find(params[:id])
  end

  def session_configuration_params
    params.require(:camp_occurrence).permit(:camp_configuration_id, :description, :cost, :begin_date, :end_date, :active)
  end
end
