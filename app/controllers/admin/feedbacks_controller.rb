# frozen_string_literal: true

# Feedback submitted by applicants from the public site.
class Admin::FeedbacksController < Admin::BaseController
  before_action :set_feedback, only: %i[show edit update destroy]

  SORTS = {
    id: 'feedbacks.id',
    genre: 'feedbacks.genre',
    message: 'feedbacks.message',
    user: 'users.email',
    created_at: 'feedbacks.created_at',
    updated_at: 'feedbacks.updated_at'
  }.freeze

  BATCH_ACTIONS = { destroy: 'Delete selected' }.freeze

  def index
    @filter = Admin::FeedbacksFilter.new(params[Admin::Filter::PARAM_KEY])
    relation = @filter.apply(Feedback.left_joins(:user).includes(:user))
    relation = apply_sort(relation, allowed: SORTS, default: :id, default_direction: :desc)

    respond_to do |format|
      format.html { @pagy, @feedbacks = paginate(relation) }
      format.csv { send_csv(csv_export, relation, filename: 'feedbacks') }
    end
  end

  def show; end

  def new
    @feedback = Feedback.new
  end

  def create
    @feedback = Feedback.new(feedback_params)

    if @feedback.save
      redirect_to admin_feedback_path(@feedback), notice: 'Feedback was successfully created.', status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @feedback.update(feedback_params)
      redirect_to admin_feedback_path(@feedback), notice: 'Feedback was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @feedback.destroy
    redirect_to admin_feedbacks_path, notice: 'Feedback was successfully deleted.', status: :see_other
  end

  def batch
    perform_batch_action(Feedback.all, BATCH_ACTIONS, redirect_to_path: admin_feedbacks_path)
  end

  private

  def set_feedback
    @feedback = Feedback.includes(:user).find(params[:id])
  end

  def feedback_params
    params.require(:feedback).permit(:user_id, :genre, :message)
  end

  def csv_export
    Admin::CsvExport.define do
      column :id
      column :genre
      column :message
      column('User') { |feedback| feedback.user&.email }
      column :created_at
      column :updated_at
    end
  end
end
