# frozen_string_literal: true

class Admin::CampnotesController < Admin::BaseController
  before_action :set_campnote, only: %i[show edit update destroy]

  SORTS = {
    id: 'campnotes.id',
    note: 'campnotes.note',
    opendate: 'campnotes.opendate',
    closedate: 'campnotes.closedate',
    notetype: 'campnotes.notetype',
    created_at: 'campnotes.created_at',
    updated_at: 'campnotes.updated_at'
  }.freeze

  BATCH_ACTIONS = { destroy: 'Delete selected' }.freeze

  CSV_EXPORT = Admin::CsvExport.define do
    column :id
    column :note
    column :opendate
    column :closedate
    column :notetype
    column :created_at
    column :updated_at
  end

  def index
    @filter = Admin::CampnotesFilter.new(params[Admin::Filter::PARAM_KEY])
    relation = @filter.apply(Campnote.all)
    relation = apply_sort(relation, allowed: SORTS, default: :opendate, default_direction: :desc)

    respond_to do |format|
      format.html { @pagy, @campnotes = paginate(relation) }
      format.csv { send_csv(CSV_EXPORT, relation, filename: 'campnotes') }
    end
  end

  def show; end

  def new
    @campnote = Campnote.new
  end

  def create
    @campnote = Campnote.new(campnote_params)

    if @campnote.save
      redirect_to admin_campnote_path(@campnote), notice: 'Campnote was successfully created.', status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @campnote.update(campnote_params)
      redirect_to admin_campnote_path(@campnote), notice: 'Campnote was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @campnote.destroy
    redirect_to admin_campnotes_path, notice: 'Campnote was successfully deleted.', status: :see_other
  end

  def batch
    perform_batch_action(Campnote.all, BATCH_ACTIONS, redirect_to_path: admin_campnotes_path)
  end

  private

  def set_campnote
    @campnote = Campnote.find(params[:id])
  end

  def campnote_params
    params.require(:campnote).permit(:note, :opendate, :closedate, :notetype)
  end
end
