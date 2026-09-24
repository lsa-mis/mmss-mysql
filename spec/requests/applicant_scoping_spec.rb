# frozen_string_literal: true

require 'rails_helper'

# Public applicant controllers must scope every lookup through current_user's enrollments: a
# signed-in applicant can never read, change or create records against another applicant's
# enrollment (a foreign id is a 404, a foreign enrollment_id in the form is ignored).
RSpec.describe 'Applicant-facing controllers scope records to the signed-in user', type: :request do
  let(:user_a) { create(:user, :with_applicant_detail) }
  let(:user_b) { create(:user, :with_applicant_detail) }
  let!(:enrollment_a) { create(:enrollment, user: user_a) }
  let!(:enrollment_b) { create(:enrollment, user: user_b) }
  let(:session) { CampOccurrence.active.first }

  # Devise's `sign_in` only sets up the next request; a normal request first writes the session
  # cookie so it survives the 404 responses (the exceptions app does not commit the session).
  before do
    sign_in user_a
    get root_path
  end

  describe 'TravelsController' do
    let!(:travel_b) { create(:travel, enrollment: enrollment_b, note: 'private note') }
    let(:travel_attributes) do
      { arrival_session: session.description_with_month_and_day, depart_session: session.description_with_month_and_day,
        arrival_transport: 'Bus', depart_transport: 'Bus' }
    end

    it "keeps the applicant's own travel pages working" do
      travel_a = create(:travel, enrollment: enrollment_a)

      get new_enrollment_travel_path(enrollment_a)
      expect(response).to have_http_status(:ok)

      get enrollment_travel_path(enrollment_a, travel_a)
      expect(response).to have_http_status(:ok)

      expect { post enrollment_travels_path(enrollment_a), params: { travel: travel_attributes } }.to change(Travel, :count).by(1)
      expect(Travel.last.enrollment).to eq(enrollment_a)
    end

    it "404s on another applicant's enrollment for show, new, edit, update and create" do
      get enrollment_travel_path(enrollment_b, travel_b)
      expect(response).to have_http_status(:not_found)

      get new_enrollment_travel_path(enrollment_b)
      expect(response).to have_http_status(:not_found)

      get edit_enrollment_travel_path(enrollment_b, travel_b)
      expect(response).to have_http_status(:not_found)

      patch enrollment_travel_path(enrollment_b, travel_b), params: { travel: { note: 'tampered' } }
      expect(response).to have_http_status(:not_found)
      expect(travel_b.reload.note).to eq('private note')

      expect { post enrollment_travels_path(enrollment_b), params: { travel: travel_attributes } }.not_to change(Travel, :count)
      expect(response).to have_http_status(:not_found)
    end

    it "404s on another applicant's travel id even under the caller's own enrollment" do
      get enrollment_travel_path(enrollment_a, travel_b)
      expect(response).to have_http_status(:not_found)
    end

    it 'ignores a client-supplied enrollment_id on create' do
      post enrollment_travels_path(enrollment_a), params: { travel: travel_attributes.merge(enrollment_id: enrollment_b.id) }

      expect(Travel.last.enrollment).to eq(enrollment_a)
    end

    it 'redirects admins (no applicant session) to the applicant login' do
      sign_out user_a
      sign_in create(:admin)
      get root_path

      get new_enrollment_travel_path(enrollment_a)
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'RecommendationsController' do
    let!(:recommendation_b) { create(:recommendation, enrollment: enrollment_b, organization: 'Private School') }
    let(:recommendation_attributes) { { email: 'rec@example.com', firstname: 'Alan', lastname: 'Turing', organization: 'Bletchley' } }

    it "keeps the applicant's own recommendation flow working" do
      get new_enrollment_recommendation_path(enrollment_a)
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('recommendation[enrollment_id]')

      expect do
        post enrollment_recommendations_path(enrollment_a), params: { recommendation: recommendation_attributes }
      end.to change(Recommendation, :count).by(1)
      expect(Recommendation.last.enrollment).to eq(enrollment_a)

      recommendation_a = Recommendation.last
      get recommendation_path(recommendation_a)
      expect(response).to have_http_status(:ok)
      get edit_recommendation_path(recommendation_a)
      expect(response).to have_http_status(:ok)
      patch recommendation_path(recommendation_a), params: { recommendation: { organization: 'Manchester' } }
      expect(response).to redirect_to(recommendation_path(recommendation_a))
      expect(recommendation_a.reload.organization).to eq('Manchester')
    end

    it "404s on another applicant's recommendation for show, edit and update" do
      get recommendation_path(recommendation_b)
      expect(response).to have_http_status(:not_found)

      get enrollment_recommendation_path(enrollment_b, recommendation_b)
      expect(response).to have_http_status(:not_found)

      get edit_recommendation_path(recommendation_b)
      expect(response).to have_http_status(:not_found)

      patch recommendation_path(recommendation_b), params: { recommendation: { organization: 'tampered' } }
      expect(response).to have_http_status(:not_found)
      expect(recommendation_b.reload.organization).to eq('Private School')
    end

    it "cannot create a recommendation for another applicant's enrollment" do
      recommendation_b.destroy!

      expect do
        post enrollment_recommendations_path(enrollment_b), params: { recommendation: recommendation_attributes }
      end.not_to change(Recommendation, :count)
      expect(response).to have_http_status(:not_found)

      get new_enrollment_recommendation_path(enrollment_b)
      expect(response).to have_http_status(:not_found)
    end

    it 'ignores a client-supplied enrollment_id on create' do
      post enrollment_recommendations_path(enrollment_a), params: { recommendation: recommendation_attributes.merge(enrollment_id: enrollment_b.id) }

      expect(Recommendation.last.enrollment).to eq(enrollment_a)
      expect(enrollment_b.reload.recommendation).to eq(recommendation_b)
    end
  end

  describe 'SessionAssignmentsController' do
    let!(:assignment_b) { create(:session_assignment, enrollment: enrollment_b, camp_occurrence: session) }

    it "404s when accepting or declining another applicant's session offer" do
      post accept_session_offer_path(assignment_b)
      expect(response).to have_http_status(:not_found)
      expect(assignment_b.reload.offer_status).to be_nil

      post decline_session_offer_path(assignment_b)
      expect(response).to have_http_status(:not_found)
      expect(assignment_b.reload.offer_status).to be_nil
    end

    it "still lets the applicant answer their own offer" do
      enrollment_a.update_columns(application_status: 'offer accepted', offer_status: 'offered')
      assignment_a = create(:session_assignment, enrollment: enrollment_a, camp_occurrence: session)

      post decline_session_offer_path(assignment_a)

      expect(response).to redirect_to(root_path)
      expect(assignment_a.reload.offer_status).to eq('declined')
    end
  end

  describe 'FinancialAidsController' do
    it "creates the request against the applicant's own enrollment whatever enrollment_id the form sends" do
      post financial_aids_path, params: { financial_aid: { enrollment_id: enrollment_b.id, note: 'help', adjusted_gross_income: 10_000 } }

      expect(FinancialAid.last.enrollment).to eq(enrollment_a)
    end

    it "404s on another applicant's financial aid request" do
      aid_b = create(:financial_aid, enrollment: enrollment_b)

      get financial_aid_path(aid_b)
      expect(response).to have_http_status(:not_found)

      patch financial_aid_path(aid_b), params: { financial_aid: { note: 'tampered', enrollment_id: enrollment_a.id } }
      expect(response).to have_http_status(:not_found)
      expect(aid_b.reload.enrollment).to eq(enrollment_b)
    end
  end
end
