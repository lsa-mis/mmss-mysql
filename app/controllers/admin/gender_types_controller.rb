# frozen_string_literal: true

# Gender Types = Gender records (the ActiveAdmin resource was registered `as: 'Gender Types'`).
class Admin::GenderTypesController < Admin::BaseController
  before_action :set_gender_type, only: %i[show edit update destroy]

  SORTS = {
    id: 'genders.id',
    name: 'genders.name',
    description: 'genders.description',
    created_at: 'genders.created_at',
    updated_at: 'genders.updated_at'
  }.freeze

  BATCH_ACTIONS = { destroy: 'Delete selected' }.freeze

  CSV_EXPORT = Admin::CsvExport.define do
    column :id
    column :name
    column :description
    column :created_at
    column :updated_at
  end

  def index
    relation = apply_sort(Gender.all, allowed: SORTS, default: :name)

    respond_to do |format|
      format.html { @pagy, @gender_types = paginate(relation) }
      format.csv { send_csv(CSV_EXPORT, relation, filename: 'gender-types') }
    end
  end

  def show; end

  def new
    @gender_type = Gender.new
  end

  def create
    @gender_type = Gender.new(gender_type_params)

    if @gender_type.save
      redirect_to admin_gender_type_path(@gender_type), notice: 'Gender type was successfully created.', status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @gender_type.update(gender_type_params)
      redirect_to admin_gender_type_path(@gender_type), notice: 'Gender type was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @gender_type.destroy
    redirect_to admin_gender_types_path, notice: 'Gender type was successfully deleted.', status: :see_other
  end

  def batch
    perform_batch_action(Gender.all, BATCH_ACTIONS, redirect_to_path: admin_gender_types_path)
  end

  private

  def set_gender_type
    @gender_type = Gender.find(params[:id])
  end

  def gender_type_params
    params.require(:gender).permit(:name, :description)
  end
end
