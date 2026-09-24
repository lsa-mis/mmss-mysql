# frozen_string_literal: true

# Faculty accounts (the Devise `Faculty` model used by the faculty student-list pages).
# Read-only apart from delete, as in ActiveAdmin: faculty register themselves and their
# access is derived from Course#faculty_uniqname.
class Admin::FacultiesController < Admin::BaseController
  before_action :set_faculty, only: %i[show destroy]

  SORTS = {
    email: 'faculties.email',
    current_sign_in_at: 'faculties.current_sign_in_at',
    sign_in_count: 'faculties.sign_in_count',
    created_at: 'faculties.created_at'
  }.freeze

  BATCH_ACTIONS = { destroy: 'Delete selected' }.freeze

  def index
    relation = apply_sort(Faculty.all, allowed: SORTS, default: :email)

    respond_to do |format|
      format.html { @pagy, @faculties = paginate(relation) }
      format.csv { send_csv(csv_export, relation, filename: 'faculties') }
    end
  end

  def show
    @courses = Course.current_camp.where(faculty_uniqname: @faculty.uniqname).includes(:camp_occurrence).order(:title)
  end

  def destroy
    @faculty.destroy
    redirect_to admin_faculties_path, notice: 'Faculty was successfully deleted.', status: :see_other
  end

  def batch
    perform_batch_action(Faculty.all, BATCH_ACTIONS, redirect_to_path: admin_faculties_path)
  end

  private

  def set_faculty
    @faculty = Faculty.find(params[:id])
  end

  def csv_export
    Admin::CsvExport.define do
      column :id
      column :email
      column :current_sign_in_at
      column :last_sign_in_at
      column :sign_in_count
      column :created_at
      column :updated_at
    end
  end
end
