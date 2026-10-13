# frozen_string_literal: true

require "rails_helper"

RSpec.describe EnrollmentsController, type: :request do
  let(:user) { create(:user, :with_applicant_detail) }
  let!(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year) }
  let!(:enrollment) do
    create(:enrollment, user: user, campyear: camp_config.camp_year,
      camp_doc_form_completed: false, application_status: "submitted",
      application_fee_required: false)
  end

  before do
    sign_in user
    get root_path
  end

  describe "PATCH /enrollments/:id — camp_doc mass-assignment guard" do
    it "rejects a crafted camp_doc_form_completed flag and does not auto-enroll" do
      # Fee waived + no accepted sessions ⇒ balance_due is 0; if camp_doc flipped, auto_enroll would enroll.
      enrollment.update_columns(application_fee_required: false)
      expect(PaymentState.new(enrollment.reload).balance_due).to eq(0)

      patch enrollment_path(enrollment), params: {
        enrollment: {
          room_mate_request: "Alex",
          camp_doc_form_completed: true,
          campyear: camp_config.camp_year - 1
        }
      }

      enrollment.reload
      expect(enrollment.room_mate_request).to eq("Alex")
      expect(enrollment.camp_doc_form_completed).to be(false)
      expect(enrollment.campyear).to eq(camp_config.camp_year)
      expect(enrollment.application_status).to eq("submitted")
      expect(enrollment.application_status).not_to eq("enrolled")
    end
  end

  describe "POST /enrollments — campyear server-side" do
    let(:other_user) { create(:user, :with_applicant_detail) }
    let(:session) { CampOccurrence.active.first || create(:camp_occurrence, camp_configuration: camp_config, active: true) }
    let!(:course) { session.courses.is_open.first || create(:course, camp_occurrence: session, status: "open") }

    before do
      sign_out user
      sign_in other_user
      get root_path
    end

    it "sets campyear from the active camp config and ignores a forged param" do
      forged_year = camp_config.camp_year - 5
      transcript = fixture_file_upload(Rails.root.join("spec/files/test.pdf"), "application/pdf")

      expect {
        post enrollments_path, params: {
          enrollment: {
            international: false,
            high_school_name: "Central High",
            high_school_address1: "1 Main St",
            high_school_city: "Ann Arbor",
            high_school_state: "MI",
            high_school_postalcode: "48104",
            high_school_country: "US",
            year_in_school: "Junior",
            anticipated_graduation_year: (Date.current.year + 1).to_s,
            personal_statement: "A" * 150,
            campyear: forged_year,
            camp_doc_form_completed: true,
            transcript: transcript,
            session_registration_ids: [session.id],
            course_registration_ids: [course.id]
          }
        }
      }.to change(Enrollment, :count).by(1)

      created = other_user.enrollments.last
      expect(created.campyear).to eq(camp_config.camp_year)
      expect(created.camp_doc_form_completed).to be(false)
    end
  end
end
