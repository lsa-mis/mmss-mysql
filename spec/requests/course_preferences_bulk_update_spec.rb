# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Course preferences bulk update', type: :request do
  let!(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year) }
  let(:user) { @user }
  let(:enrollment) { @enrollment }

  before do
    CampConfiguration.update_all(active: false)
    camp_config.update!(active: true)
    @user = create(:user)
    @enrollment = create(:enrollment, user: @user, campyear: camp_config.camp_year)
    sign_in @user

    # Factory may register only one course per session; add another course + preference in the same session for duplicate-rank coverage.
    sample = @enrollment.course_preferences.joins(:course).first
    if sample
      occ = sample.course.camp_occurrence
      extra = create(:course, camp_occurrence: occ, status: 'open', title: 'Extra course for ranking spec')
      @enrollment.course_registration_ids = (@enrollment.course_registration_ids + [extra.id]).uniq
      @enrollment.save!
      @enrollment.reload
    end
  end

  def rankings_payload_for(enrollment)
    enrollment.course_preferences.includes(:course).group_by { |cp| cp.course.camp_occurrence_id }.each_with_object({}) do |(_occ_id, prefs), acc|
      prefs.each_with_index do |cp, index|
        acc[cp.id.to_s] = (index + 1).to_s
      end
    end
  end

  describe 'PATCH /enrollments/:enrollment_id/course_preferences/bulk_update' do
    it 'saves unique sequential ranks per session and redirects to home' do
      rankings = rankings_payload_for(enrollment)
      patch bulk_update_enrollment_course_preferences_path(enrollment), params: { rankings: rankings }

      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to match(/successfully saved/i)
      expect(enrollment.reload.course_rankings_complete?).to be true
    end

    it 're-renders index when ranks are duplicated within a session' do
      occ_id = enrollment.course_preferences.joins(:course).pick('courses.camp_occurrence_id')
      same_session = enrollment.course_preferences.joins(:course)
        .where(courses: { camp_occurrence_id: occ_id })
        .order(:id)
        .limit(2)
        .to_a
      expect(same_session.size).to be >= 2

      rankings = rankings_payload_for(enrollment)
      a = same_session[0].id.to_s
      b = same_session[1].id.to_s
      rankings[a] = '1'
      rankings[b] = '1'

      patch bulk_update_enrollment_course_preferences_path(enrollment), params: { rankings: rankings }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(enrollment.reload.course_rankings_complete?).to be false
    end
  end
end
