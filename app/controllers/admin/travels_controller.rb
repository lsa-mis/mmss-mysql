# frozen_string_literal: true

class Admin::TravelsController < Admin::BaseController
  before_action :set_travel, only: %i[show edit update destroy]

  SORTS = {
    applicant: 'applicant_details.lastname',
    arrival_session: 'travels.arrival_session',
    depart_session: 'travels.depart_session',
    arrival_transport: 'travels.arrival_transport',
    arrival_date: 'travels.arrival_date',
    arrival_time: 'travels.arrival_time',
    depart_transport: 'travels.depart_transport',
    depart_date: 'travels.depart_date',
    depart_time: 'travels.depart_time',
    created_at: 'travels.created_at',
    updated_at: 'travels.updated_at'
  }.freeze

  BATCH_ACTIONS = { destroy: 'Delete selected' }.freeze

  def index
    @filter = Admin::TravelsFilter.new(params[Admin::Filter::PARAM_KEY])
    relation = @filter.apply(base_relation)
    relation = apply_sort(relation, allowed: SORTS, default: :arrival_date, default_direction: :desc)

    respond_to do |format|
      format.html { @pagy, @travels = paginate(relation) }
      format.csv { send_csv(csv_export, relation, filename: 'travels') }
    end
  end

  def show; end

  def new
    @travel = Travel.new
  end

  def create
    @travel = Travel.new(travel_params)

    if @travel.save
      redirect_to admin_travel_path(@travel), notice: 'Travel was successfully created.', status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @travel.update(travel_params)
      redirect_to admin_travel_path(@travel), notice: 'Travel was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @travel.destroy
    redirect_to admin_travels_path, notice: 'Travel was successfully deleted.', status: :see_other
  end

  def batch
    perform_batch_action(Travel.all, BATCH_ACTIONS, redirect_to_path: admin_travels_path)
  end

  private

  def set_travel
    @travel = Travel.includes(enrollment: %i[user applicant_detail]).find(params[:id])
  end

  def base_relation
    Travel.left_joins(enrollment: :applicant_detail).preload(enrollment: %i[user applicant_detail])
  end

  def travel_params
    params.require(:travel).permit(:enrollment_id, :arrival_session, :depart_session,
                                   :arrival_transport, :arrival_carrier, :arrival_route_num, :arrival_date, :arrival_time,
                                   :depart_transport, :depart_carrier, :depart_route_num, :depart_date, :depart_time, :note)
  end

  def csv_export
    view = helpers
    Admin::CsvExport.define do
      column('Name') { |travel| travel.enrollment.applicant_detail&.full_name }
      column('email') { |travel| travel.enrollment.user.email }
      column :arrival_session
      column :depart_session
      column :arrival_transport
      column :arrival_carrier
      column :arrival_route_num
      column(:arrival_date) { |travel| view.show_date(travel.arrival_date) }
      column(:arrival_time) { |travel| view.show_time(travel.arrival_time) }
      column :depart_transport
      column :depart_carrier
      column :depart_route_num
      column(:depart_date) { |travel| view.show_date(travel.depart_date) }
      column(:depart_time) { |travel| view.show_time(travel.depart_time) }
      column :note
    end
  end
end
