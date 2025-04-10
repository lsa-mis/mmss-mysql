class FeedbackMailerPreview < ActionMailer::Preview
  def feedback_email
    feedback = Feedback.new(
      user_id: User.first.id,
      message: "This is a sample feedback message for preview purposes.",
      genre: "Bug Report"
    )
    FeedbackMailer.with(feedback: feedback).feedback_email
  end
end
