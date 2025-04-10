class OfferMailerPreview < ActionMailer::Preview
  def offer_email
    # Create test data
    camp_config = CampConfiguration.find_by(active: true) ||
                 CampConfiguration.create!(
                   active: true,
                   offer_letter: "This is a sample offer letter for preview purposes.",
                   camp_year: Date.today.year,
                   student_packet_url: "https://example.com/packet.pdf"
                 )

    # Create a test course and session
    course = Course.first ||
            Course.create!(
              display_name: "Sample Course",
              camp_configuration: camp_config
            )

    camp_occurrence = CampOccurrence.first ||
                     CampOccurrence.create!(
                       display_name: "Session 1 - June 2025",
                       camp_configuration: camp_config
                     )

    # Create a test user and their details
    user = User.first ||
           User.create!(
             email: 'test@example.com',
             password: 'password123'
           )

    applicant = ApplicantDetail.find_by(user_id: user.id) ||
                ApplicantDetail.create!(
                  user_id: user.id,
                  firstname: "Test",
                  lastname: "Student"
                )

    # Create enrollment with course and session assignments
    enrollment = Enrollment.find_by(user_id: user.id) ||
                Enrollment.create!(
                  user_id: user.id,
                  camp_configuration: camp_config,
                  application_status: "application complete",
                  application_deadline: 1.month.from_now,
                  campyear: camp_config.camp_year
                )

    # Ensure we have course and session assignments
    course_assignment = CourseAssignment.find_by(enrollment: enrollment) ||
                       CourseAssignment.create!(
                         enrollment: enrollment,
                         course: course,
                         wait_list: false
                       )

    session_assignment = SessionAssignment.find_by(enrollment: enrollment) ||
                        SessionAssignment.create!(
                          enrollment: enrollment,
                          camp_occurrence: camp_occurrence
                        )

    # Send the preview
    OfferMailer.offer_email(user.id)
  end

  def offer_accepted_email
    # Reuse the same test data from offer_email
    offer_email  # This will ensure all test data exists
    user = User.first
    session_assignment = SessionAssignment.first
    course_assignment = CourseAssignment.first

    OfferMailer.offer_accepted_email(user.id, session_assignment, course_assignment)
  end

  def offer_declined_email
    # Reuse the same test data from offer_email
    offer_email  # This will ensure all test data exists
    user = User.first
    session_assignment = SessionAssignment.first
    course_assignment = CourseAssignment.first

    OfferMailer.offer_declined_email(user.id, session_assignment, course_assignment)
  end
end
