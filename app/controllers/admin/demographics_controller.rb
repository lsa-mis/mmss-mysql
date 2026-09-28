# frozen_string_literal: true

# Demographic options offered on the applicant details form. Records flagged `protected`
# (e.g. "Other") are read-only: they can be viewed but not edited or deleted.
class Admin::DemographicsController < Admin::BaseController
  before_action :set_demographic, only: %i[show edit update destroy]
  before_action :reject_protected, only: %i[update destroy]

  SORTS = {
    name: 'demographics.name',
    description: 'demographics.description',
    protected: 'demographics.protected',
    created_at: 'demographics.created_at',
    updated_at: 'demographics.updated_at'
  }.freeze

  BATCH_ACTIONS = { destroy: 'Delete selected' }.freeze

  CSV_EXPORT = Admin::CsvExport.define do
    column :id
    column :name
    column :description
    column :protected
    column :created_at
    column :updated_at
  end

  def index
    relation = apply_sort(Demographic.all, allowed: SORTS, default: :name)

    respond_to do |format|
      format.html { @pagy, @demographics = paginate(relation) }
      format.csv { send_csv(CSV_EXPORT, relation, filename: 'demographics') }
    end
  end

  def show; end

  def new
    @demographic = Demographic.new
  end

  def create
    @demographic = Demographic.new(demographic_params)

    if @demographic.save
      redirect_to admin_demographic_path(@demographic), notice: 'Demographic was successfully created.', status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @demographic.update(demographic_params)
      redirect_to admin_demographic_path(@demographic), notice: 'Demographic was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @demographic.destroy
      redirect_to admin_demographics_path, notice: 'Demographic was successfully deleted.', status: :see_other
    else
      redirect_to admin_demographic_path(@demographic), flash: { error: @demographic.errors.full_messages.to_sentence }, status: :see_other
    end
  end

  # Protected records refuse to be destroyed (Demographic#prevent_protected_deletion), so the
  # count in the notice only includes the records that were actually deleted.
  def batch
    perform_batch_action(Demographic.all, BATCH_ACTIONS, redirect_to_path: admin_demographics_path)
  end

  private

  def set_demographic
    @demographic = Demographic.find(params[:id])
  end

  def reject_protected
    return unless @demographic.protected?

    message = action_name == 'destroy' ? 'Cannot delete protected demographic records' : 'Cannot modify protected demographic records'
    redirect_to admin_demographic_path(@demographic), flash: { error: message }, status: :see_other
  end

  def demographic_params
    params.require(:demographic).permit(:name, :description)
  end
end
