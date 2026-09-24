# frozen_string_literal: true

module Admin::FeedbacksHelper
  # `[label, value]` pairs for the genre select. A persisted genre outside Feedback::GENRES
  # (legacy data) is kept as a selectable option so editing the message does not blank it.
  def admin_feedback_genre_options(feedback)
    options = Feedback::GENRES.map { |value, label| [label, value] }
    current = feedback.genre
    options << [current, current] if current.present? && Feedback::GENRES.exclude?(current)
    options
  end
end
