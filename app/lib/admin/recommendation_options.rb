# frozen_string_literal: true

# "Applicant Name" options for the Recupload form: current-year recommendations labelled with the
# applicant's name and the recommender, alphabetically. `include:` keeps an older persisted
# recommendation selectable.
class Admin::RecommendationOptions
  def self.current_camp(include: nil)
    recommendations = Recommendation.where(enrollment_id: Enrollment.current_camp_year_applications)
                                    .preload(enrollment: %i[user applicant_detail]).to_a
    recommendations << include if include && recommendations.none? { |recommendation| recommendation.id == include.id }
    recommendations.map { |recommendation| [label(recommendation), recommendation.id] }
                   .sort_by { |label, _id| label.downcase }
  end

  def self.label(recommendation)
    "#{Admin::EnrollmentOptions.label(recommendation.enrollment)} (recommender: #{recommendation.full_name})"
  end
end
