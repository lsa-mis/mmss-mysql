# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EnrollmentsController, type: :controller do
  describe 'GET #show' do
    let(:user) { create(:user) }
    let(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year) }

    before do
      CampConfiguration.update_all(active: false)
      camp_config.update(active: true)
      sign_in user
    end

    context 'when user has no current camp year enrollment' do
      it 'redirects to root with alert and does not raise' do
        get :show, params: { id: 1 }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('No current enrollment found.')
      end
    end

    context 'when user has a current camp year enrollment' do
      let!(:enrollment) { create(:enrollment, user: user, campyear: camp_config.camp_year) }

      it 'renders show successfully' do
        get :show, params: { id: enrollment.id }
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'POST #withdraw' do
    let(:admin) { create(:admin) }
    let(:user) { create(:user) }
    let(:camp_config) { create(:camp_configuration, :active, camp_year: Date.current.year) }
    let(:camp_occurrence) { create(:camp_occurrence, camp_configuration: camp_config, description: 'Session 1') }
    let(:course) { create(:course, camp_occurrence: camp_occurrence, title: 'Test Course') }
    let(:enrollment) { create(:enrollment, :enrolled, user: user, campyear: camp_config.camp_year) }
    let!(:course_assignment) { create(:course_assignment, enrollment: enrollment, course: course) }

    before do
      CampConfiguration.update_all(active: false)
      camp_config.update(active: true)
      sign_in admin
    end

    context 'when enrollment has course assignments' do
      it 'deletes all course assignments' do
        expect {
          post :withdraw, params: { id: enrollment.id }
        }.to change { enrollment.course_assignments.reload.count }.from(1).to(0)
      end

      it 'updates enrollment status to withdrawn' do
        post :withdraw, params: { id: enrollment.id }
        enrollment.reload
        expect(enrollment.application_status).to eq('withdrawn')
        expect(enrollment.application_status_updated_on).to eq(Date.today)
      end

      it 'redirects to admin application path with notice' do
        post :withdraw, params: { id: enrollment.id }
        expect(response).to redirect_to(admin_application_path(enrollment))
        expect(flash[:notice]).to include('Enrollment has been withdrawn')
        expect(flash[:notice]).to include('Course: Test Course')
        expect(flash[:notice]).to include('Session: Session 1')
      end
    end

    context 'when enrollment has no course assignments' do
      before do
        enrollment.course_assignments.destroy_all
      end

      it 'updates enrollment status to withdrawn' do
        post :withdraw, params: { id: enrollment.id }
        enrollment.reload
        expect(enrollment.application_status).to eq('withdrawn')
      end

      it 'shows a notice without course assignment details' do
        post :withdraw, params: { id: enrollment.id }
        expect(flash[:notice]).to eq('Enrollment has been withdrawn.')
      end
    end

    context 'when enrollment has multiple course assignments' do
      let(:camp_occurrence2) { create(:camp_occurrence, camp_configuration: camp_config, description: 'Session 2') }
      let(:course2) { create(:course, camp_occurrence: camp_occurrence2, title: 'Test Course 2') }
      let!(:course_assignment2) { create(:course_assignment, enrollment: enrollment, course: course2) }

      it 'deletes all course assignments' do
        expect {
          post :withdraw, params: { id: enrollment.id }
        }.to change { enrollment.course_assignments.reload.count }.from(2).to(0)
      end

      it 'includes all deleted course assignments in the notice' do
        post :withdraw, params: { id: enrollment.id }
        expect(flash[:notice]).to include('Course: Test Course')
        expect(flash[:notice]).to include('Course: Test Course 2')
        expect(flash[:notice]).to include('Session: Session 1')
        expect(flash[:notice]).to include('Session: Session 2')
      end
    end
  end
end
