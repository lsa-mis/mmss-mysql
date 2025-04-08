class OfferMailer < ApplicationMailer
  # @param user_id [Integer] The ID of the user to send the offer email to
  # @return [Mail::Message] The email message that was sent
  def offer_email(user_id)
    raise ArgumentError, 'user_id cannot be nil' if user_id.nil?
    setup_common_variables(user_id)
    @assigned_courses = @enrollment.course_assignments.where(wait_list: false)
    @assigned_sessions = @enrollment.session_assignments

    result = mail(to: @user.email,
                 subject: 'University of Michigan MMSS: Offer to attend Michigan Math and Science Scholars') do |format|
      format.html
      format.text
    end

    update_application_status if @enrollment.present?
    result
  rescue StandardError => e
    log_error("Failed to send offer email for user #{user_id}", e)
    raise
  end

  def offer_accepted_email(user_id, session_assignment, course_assignment)
    setup_common_variables(user_id)
    @session_assignment = session_assignment
    @course_assignment = format_course_assignment(course_assignment)

    mail(to: @user.email, subject: 'UM MMSS: Offer Accepted')
  rescue StandardError => e
    log_error("Failed to send offer accepted email for user #{user_id}", e)
    raise
  end

  def offer_declined_email(user_id, session_assignment, course_assignment)
    setup_common_variables(user_id)
    @session_assignment = session_assignment
    @course_assignment = format_course_assignment(course_assignment)

    mail(to: @user.email, subject: 'UM MMSS: Offer Declined')
  rescue StandardError => e
    log_error("Failed to send offer declined email for user #{user_id}", e)
    raise
  end

  private

  def setup_common_variables(user_id)
    @user = find_user(user_id)
    @camp_config = current_camp_config
    @offer_letter_text = @camp_config&.offer_letter
    @application = find_application(user_id)
    @enrollment = find_enrollment(user_id)
    @url = ConstantData::HOST_URL
  end

  def find_user(user_id)
    User.find(user_id)
  rescue ActiveRecord::RecordNotFound => e
    log_error("User not found with ID: #{user_id}", e)
    raise
  end

  def current_camp_config
    @current_camp_config ||= CampConfiguration.find_by(active: true)
  end

  def find_application(user_id)
    ApplicantDetail.find_by(user_id: user_id)
  end

  def find_enrollment(user_id)
    Enrollment.current_camp_year_applications.find_by(user_id: user_id)
  end

  def format_course_assignment(course_assignment)
    return 'Contact MMSS admin to get a course assignment' if course_assignment.nil?

    course_assignment.course&.display_name || 'Course name not available'
  end

  def update_application_status
    return unless @enrollment.present? && @enrollment.application_status != 'application complete'

    @enrollment.update(
      application_status: 'application complete',
      application_status_updated_on: Date.current
    )
  end

  def log_error(message, error)
    Rails.logger.error("#{message}: #{error.message}")
    Rails.logger.error(error.backtrace.join("\n"))
  end
end
