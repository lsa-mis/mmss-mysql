# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Wave 5 SiteImprove accessibility (course rankings & birthdate)", type: :request do
  describe "GET /enrollments/:enrollment_id/course_preferences (LRA-1463)" do
    let!(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year) }
    let(:user) { create(:user) }
    let(:enrollment) { create(:enrollment, user: user, campyear: camp_config.camp_year) }

    before do
      CampConfiguration.update_all(active: false)
      camp_config.update!(active: true)

      # Ensure at least two courses in one session so move controls are meaningful.
      sample = enrollment.course_preferences.joins(:course).first
      if sample
        occ = sample.course.camp_occurrence
        extra = create(:course, camp_occurrence: occ, status: "open", title: "Wave5 Ranking Course")
        enrollment.course_registration_ids = (enrollment.course_registration_ids + [extra.id]).uniq
        enrollment.save!
        enrollment.reload
      end

      sign_in user
    end

    it "puts each course title before move controls with named up/down buttons" do
      get enrollment_course_preferences_path(enrollment)

      expect(response).to have_http_status(:ok)
      body = response.body

      preference = enrollment.course_preferences.includes(:course).find { |cp| cp.course.title == "Wave5 Ranking Course" }
      preference ||= enrollment.course_preferences.includes(:course).first
      title = preference.course.title
      title_id = "course-ranking-title-#{preference.id}"

      expect(body).to include(%(id="#{title_id}"))
      expect(body).to include(%(tabindex="0"))
      expect(body).to include(%(aria-label="Move #{title} up"))
      expect(body).to include(%(aria-label="Move #{title} down"))

      title_pos = body.index(%(id="#{title_id}"))
      up_pos = body.index(%(aria-label="Move #{title} up"))
      down_pos = body.index(%(aria-label="Move #{title} down"))
      expect(title_pos).to be < up_pos
      expect(up_pos).to be < down_pos
    end
  end

  describe "GET /applicant_details/:id/edit birthdate (LRA-1460, LRA-1461)" do
    let(:user) { create(:user, :with_applicant_detail) }

    before { sign_in user }

    it "renders a native date input with min/max age bounds (no flatpickr)" do
      detail = user.applicant_detail
      get edit_applicant_detail_path(detail)

      expect(response).to have_http_status(:ok)
      body = response.body

      min = (Date.current - 19.years).strftime("%Y-%m-%d")
      max = (Date.current - 12.years).strftime("%Y-%m-%d")

      expect(body).to match(
        /<input\b(?=[^>]*\btype="date")(?=[^>]*\bname="applicant_detail\[birthdate\]")(?=[^>]*\bmin="#{Regexp.escape(min)}")(?=[^>]*\bmax="#{Regexp.escape(max)}")(?=[^>]*\srequired(?:\s|=|\/|>))[^>]*>/
      )
      expect(body).not_to include("flatpickr")
      expect(body).not_to include('data-controller="flatpickr"')
    end
  end
end
