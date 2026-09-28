# frozen_string_literal: true

class Admin::CampConfigurationsController < Admin::BaseController
  before_action :set_camp_configuration, only: %i[show edit update destroy]

  SORTS = {
    camp_year: 'camp_configurations.camp_year',
    application_open: 'camp_configurations.application_open',
    application_close: 'camp_configurations.application_close',
    priority: 'camp_configurations.priority',
    application_materials_due: 'camp_configurations.application_materials_due',
    camper_acceptance_due: 'camp_configurations.camper_acceptance_due',
    active: 'camp_configurations.active',
    application_fee: 'camp_configurations.application_fee_cents',
    application_fee_required: 'camp_configurations.application_fee_required',
    created_at: 'camp_configurations.created_at',
    updated_at: 'camp_configurations.updated_at'
  }.freeze

  BATCH_ACTIONS = { destroy: 'Delete selected' }.freeze

  CSV_EXPORT = Admin::CsvExport.define do
    column :id
    column :camp_year
    column :application_open
    column :application_close
    column :priority
    column :application_materials_due
    column :camper_acceptance_due
    column :active
    column :offer_letter
    column :student_packet_url
    column('Application fee') { |camp| camp.application_fee.format }
    column :reject_letter
    column :waitlist_letter
    column :application_fee_required
    column :created_at
    column :updated_at
  end

  def index
    @filter = Admin::CampConfigurationsFilter.new(params[Admin::Filter::PARAM_KEY])
    relation = @filter.apply(CampConfiguration.all)
    relation = apply_sort(relation, allowed: SORTS, default: :camp_year, default_direction: :desc)

    respond_to do |format|
      format.html { @pagy, @camp_configurations = paginate(relation) }
      format.csv { send_csv(CSV_EXPORT, relation, filename: 'camp-configurations') }
    end
  end

  def show; end

  # The letters and fee are copied from the most recent camp so admins only have to fill in the
  # new year and dates (CampConfiguration#dup clears those).
  def new
    last_camp = CampConfiguration.order(:id).last
    if last_camp
      @camp_configuration = last_camp.dup
      flash.now[:alert] = "Each letter's text and camp fee were copied from previous camp. Don't forget to edit them."
    else
      @camp_configuration = CampConfiguration.new
    end
  end

  def create
    @camp_configuration = CampConfiguration.new(camp_configuration_params)

    if @camp_configuration.save
      redirect_to admin_camp_configuration_path(@camp_configuration), notice: 'Camp configuration was successfully created.',
                                                                       status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @camp_configuration.update(camp_configuration_params)
      redirect_to admin_camp_configuration_path(@camp_configuration), notice: 'Camp configuration was successfully updated.',
                                                                       status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @camp_configuration.destroy
    redirect_to admin_camp_configurations_path, notice: 'Camp configuration was successfully deleted.', status: :see_other
  end

  def batch
    perform_batch_action(CampConfiguration.all, BATCH_ACTIONS, redirect_to_path: admin_camp_configurations_path)
  end

  private

  def set_camp_configuration
    @camp_configuration = CampConfiguration.find(params[:id])
  end

  def camp_configuration_params
    params.require(:camp_configuration).permit(
      :camp_year, :application_open, :application_close, :priority, :application_materials_due,
      :camper_acceptance_due, :active, :offer_letter, :student_packet_url, :application_fee,
      :reject_letter, :waitlist_letter, :application_fee_required
    )
  end
end
