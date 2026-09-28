# frozen_string_literal: true

class Admin::ActivitiesController < Admin::BaseController
  before_action :set_activity, only: %i[show edit update destroy]

  SORTS = {
    session: 'camp_occurrences.description',
    description: 'activities.description',
    cost: 'activities.cost_cents',
    date_occurs: 'activities.date_occurs',
    active: 'activities.active',
    created_at: 'activities.created_at',
    updated_at: 'activities.updated_at'
  }.freeze

  BATCH_ACTIONS = { destroy: 'Delete selected', toggle_active: 'Toggle active' }.freeze

  CSV_EXPORT = Admin::CsvExport.define do
    column :id
    column('Session') { |activity| activity.camp_occurrence.description }
    column :description
    column :cost
    column :date_occurs
    column :active
    column :created_at
    column :updated_at
  end

  def index
    @filter = Admin::ActivitiesFilter.new(params[Admin::Filter::PARAM_KEY])
    relation = @filter.apply(Activity.joins(:camp_occurrence).includes(:camp_occurrence))
    relation = apply_sort(relation, allowed: SORTS, default: :date_occurs, default_direction: :desc)

    respond_to do |format|
      format.html { @pagy, @activities = paginate(relation) }
      format.csv { send_csv(CSV_EXPORT, relation, filename: 'activities') }
    end
  end

  def show; end

  def new
    @activity = Activity.new
  end

  def create
    @activity = Activity.new(activity_params)

    if @activity.save
      redirect_to admin_activity_path(@activity), notice: 'Activity was successfully created.', status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @activity.update(activity_params)
      redirect_to admin_activity_path(@activity), notice: 'Activity was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @activity.destroy
    redirect_to admin_activities_path, notice: 'Activity was successfully deleted.', status: :see_other
  end

  def batch
    perform_batch_action(Activity.all, BATCH_ACTIONS, redirect_to_path: admin_activities_path)
  end

  private

  def batch_toggle_active(records)
    toggled = records.to_a.count { |record| record.update(active: !record.active) }
    "Toggled active status for #{toggled} #{'activity'.pluralize(toggled)}."
  end

  def set_activity
    @activity = Activity.includes(:camp_occurrence).find(params[:id])
  end

  def activity_params
    params.require(:activity).permit(:camp_occurrence_id, :description, :cost, :date_occurs, :active)
  end
end
