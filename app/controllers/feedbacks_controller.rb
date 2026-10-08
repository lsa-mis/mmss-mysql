# frozen_string_literal: true

class FeedbacksController < ApplicationController
  # Feedback belongs to an applicant account (current_user.feedbacks); the footer only offers the
  # link to signed-in users.
  before_action :authenticate_user!

  def index
    redirect_to root_path
  end

  def show
    redirect_to root_path
  end

  def new
    @feedback = current_user.feedbacks.new
  end

  def create
    @feedback = current_user.feedbacks.new(feedback_params)

    if @feedback.save
      FeedbackMailer.with(feedback: @feedback).feedback_email.deliver_now
      redirect_to root_path, notice: 'Feedback was successfully created.', status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  private

    def feedback_params
      params.require(:feedback).permit(:user_id, :genre, :message)
    end

end
