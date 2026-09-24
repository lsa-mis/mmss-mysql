# frozen_string_literal: true

module Admin::ApplicantDetailsHelper
  # Gender name from the per-request lookup built by the controller (falls back to a query).
  def admin_applicant_gender_name(applicant_detail, lookup = @genders)
    id = applicant_detail.gender.to_s
    return admin_empty_value if id.blank?

    (lookup && lookup[id]) || Gender.find_by(id: id)&.name || id
  end

  def admin_gender_options
    Gender.order(:name).pluck(:name, :id).map { |name, id| [name, id.to_s] }
  end

  def admin_demographic_options
    Demographic.order(:name).pluck(:name, :id)
  end

  # Users who can still get an applicant detail (no record yet), plus the record's own user.
  def admin_applicant_detail_user_options(applicant_detail)
    options = User.where.missing(:applicant_detail).order(:email).pluck(:email, :id)
    if applicant_detail.user_id && options.none? { |_email, id| id == applicant_detail.user_id }
      options << [applicant_detail.user.email, applicant_detail.user_id]
    end
    options
  end

  # Email linking to the applicant's latest application when there is one. `latest_enrollment_id`
  # is the SQL column added by the index relation; the show page passes the record instead.
  def admin_applicant_detail_email(applicant_detail, enrollment_id = nil)
    email = applicant_detail.user.email
    enrollment_id ||= applicant_detail.try(:latest_enrollment_id)
    return email if enrollment_id.blank?

    link_to email, admin_application_path(enrollment_id), title: 'Latest application'
  end
end
