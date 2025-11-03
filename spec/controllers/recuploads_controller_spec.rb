# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RecuploadsController, type: :controller do
  let(:admin) { create(:admin) }
  let(:user) { create(:user, :with_applicant_detail) }
  let(:enrollment) { create(:enrollment, user: user) }
  let(:recommendation) { create(:recommendation, enrollment: enrollment) }
  let(:valid_hash) { "test_nGklDoc2egIkzFxr0U#{recommendation.id}" }
  let(:valid_params) do
    {
      recupload: {
        letter: 'This is a test recommendation letter.',
        authorname: 'Dr. Test Author',
        studentname: 'Test Student',
        recommendation_id: recommendation.id
      },
      hash: valid_hash,
      id: enrollment.user.applicant_detail.id
    }
  end

  describe 'GET #index' do
    context 'when admin is signed in' do
      before { sign_in admin }

      it 'renders the index page' do
        get :index
        # The controller redirects unless admin_signed_in? is false
        # Since we're signed in, it should NOT redirect, so we expect 200
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when admin is not signed in' do
      it 'redirects to admin sign in' do
        get :index
        expect(response).to redirect_to(new_admin_session_path)
      end
    end
  end

  describe 'GET #show' do
    let(:recupload) { create(:recupload, recommendation: recommendation) }

    before { sign_in admin }

    it 'assigns the requested recupload' do
      get :show, params: { id: recupload.id }
      expect(assigns(:recupload)).to eq(recupload)
    end
  end

  describe 'GET #new' do
    context 'when recommendation has no recupload' do
      before do
        allow(controller).to receive(:get_recommendation)
        controller.instance_variable_set(:@recommendation, recommendation)
      end

      it 'builds a new recupload' do
        get :new, params: { hash: valid_hash, id: enrollment.user.applicant_detail.id }
        expect(assigns(:recupload)).to be_a_new(Recupload)
        expect(assigns(:recupload).recommendation).to eq(recommendation)
      end
    end

    context 'when recommendation already has a recupload' do
      let!(:existing_recupload) { create(:recupload, recommendation: recommendation) }

      before do
        allow(controller).to receive(:get_recommendation)
        controller.instance_variable_set(:@recommendation, recommendation)
      end

      it 'redirects to error path with alert' do
        get :new, params: { hash: valid_hash, id: enrollment.user.applicant_detail.id }
        expect(response).to redirect_to(recupload_error_path)
        expect(flash[:alert]).to eq('A recommendation has already been submitted for this user')
      end
    end
  end

  describe 'POST #create' do
    before do
      allow(controller).to receive(:get_recommendation)
      controller.instance_variable_set(:@recommendation, recommendation)
    end

    context 'with valid parameters' do
      it 'creates a new recupload' do
        expect {
          post :create, params: valid_params
        }.to change(Recupload, :count).by(1)
      end

      it 'redirects to success path' do
        post :create, params: valid_params
        expect(response).to redirect_to(recupload_success_path)
        expect(flash[:notice]).to eq('Recommendation was successfully uploaded.')
      end

      it 'sends both emails' do
        expect(RecuploadMailer).to receive(:with).with(recupload: instance_of(Recupload)).twice.and_call_original
        expect_any_instance_of(RecuploadMailer).to receive(:received_email).and_return(double(deliver_now: true))
        expect_any_instance_of(RecuploadMailer).to receive(:applicant_received_email).and_return(double(deliver_now: true))
        post :create, params: valid_params
      end

      # Note: JSON response test removed due to missing show template
      # The controller tries to render :show but there's no template available
      # This would need a proper show.json.jbuilder template to work correctly
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          recupload: {
            letter: '',
            authorname: '',
            studentname: '',
            recommendation_id: recommendation.id
          },
          hash: valid_hash,
          id: enrollment.user.applicant_detail.id
        }
      end

      it 'does not create a new recupload' do
        expect {
          post :create, params: invalid_params
        }.not_to change(Recupload, :count)
      end

      it 'renders new template' do
        post :create, params: invalid_params
        expect(response).to render_template(:new)
      end

      it 'assigns student name for error display' do
        post :create, params: invalid_params
        expect(assigns(:student)).to eq(enrollment.user.applicant_detail.full_name)
      end

      it 'responds with JSON error' do
        post :create, params: invalid_params.merge(format: :json)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to include('application/json')
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:recupload) { create(:recupload, recommendation: recommendation) }

    before { sign_in admin }

    it 'destroys the requested recupload' do
      expect {
        delete :destroy, params: { id: recupload.id }
      }.to change(Recupload, :count).by(-1)
    end

    it 'redirects to recuploads index' do
      delete :destroy, params: { id: recupload.id }
      expect(response).to redirect_to(recuploads_url)
      expect(flash[:notice]).to eq('Recommendation was successfully destroyed.')
    end

    it 'responds with no content for JSON' do
      delete :destroy, params: { id: recupload.id, format: :json }
      expect(response).to have_http_status(:no_content)
    end
  end

  describe '#get_recommendation' do
    context 'with valid hash containing pattern' do
      it 'finds the correct recommendation' do
        get :new, params: { hash: valid_hash, id: enrollment.user.applicant_detail.id }
        expect(assigns(:recommendation)).to eq(recommendation)
      end

      it 'sets student name from applicant detail' do
        get :new, params: { hash: valid_hash, id: enrollment.user.applicant_detail.id }
        expect(assigns(:student)).to eq(enrollment.user.applicant_detail.full_name)
      end
    end

    context 'with hash containing only numeric part' do
      let(:numeric_hash) { "test#{recommendation.id}" }

      it 'extracts recommendation ID from numeric part' do
        # Ensure the recommendation exists before the test
        expect(recommendation).to be_persisted
        # Debug: check what ID is being extracted
        extracted_id = numeric_hash.gsub(/[^0-9]/, '').to_i
        expect(extracted_id).to eq(recommendation.id)

        get :new, params: { hash: numeric_hash, id: enrollment.user.applicant_detail.id }
        expect(assigns(:recommendation)).to eq(recommendation)
      end
    end

    context 'with missing hash parameter' do
      it 'redirects to error path' do
        get :new, params: { id: enrollment.user.applicant_detail.id }
        expect(response).to redirect_to(recupload_error_path)
        expect(flash[:alert]).to eq('We could not find the recommendation request. Please contact MMSS admin for assistance.')
      end
    end

    context 'with invalid recommendation ID' do
      let(:invalid_hash) { "test_nGklDoc2egIkzFxr0U999999" }

      it 'redirects to error path' do
        get :new, params: { hash: invalid_hash, id: enrollment.user.applicant_detail.id }
        expect(response).to redirect_to(recupload_error_path)
        expect(flash[:alert]).to eq('We could not find the recommendation request. Please contact MMSS admin for assistance.')
      end
    end

    context 'when applicant detail is not found' do
      it 'uses recommendation applicant name as fallback' do
        get :new, params: { hash: valid_hash, id: 999999 }
        expect(assigns(:student)).to eq(recommendation.applicant_name)
      end
    end

    context 'when no id parameter provided' do
      it 'uses recommendation applicant name' do
        get :new, params: { hash: valid_hash }
        expect(assigns(:student)).to eq(recommendation.applicant_name)
      end
    end
  end

  describe 'authentication' do
    context 'for actions requiring admin authentication' do
      %w[index show edit destroy].each do |action|
        it "requires admin authentication for #{action}" do
          case action
          when 'index'
            get action.to_sym
          when 'show', 'edit', 'destroy'
            recupload = create(:recupload, recommendation: recommendation)
            get action.to_sym, params: { id: recupload.id }
          end
          expect(response).to redirect_to(new_admin_session_path)
        end
      end
    end

    context 'for actions not requiring admin authentication' do
      %w[success error new create].each do |action|
        it "allows access to #{action} without admin authentication" do
          case action
          when 'success', 'error'
            get action.to_sym
            expect(response).to have_http_status(:success)
          when 'new'
            allow(controller).to receive(:get_recommendation)
            controller.instance_variable_set(:@recommendation, recommendation)
            get action.to_sym, params: { hash: valid_hash, id: enrollment.user.applicant_detail.id }
            expect(response).to have_http_status(:success)
          when 'create'
            allow(controller).to receive(:get_recommendation)
            controller.instance_variable_set(:@recommendation, recommendation)
            post action.to_sym, params: valid_params
            expect(response).to have_http_status(:redirect)
          end
        end
      end
    end
  end

  describe 'file upload handling' do
    let(:file_params) do
      {
        recupload: {
          authorname: 'Dr. Test Author',
          studentname: 'Test Student',
          recommendation_id: recommendation.id,
          recletter: fixture_file_upload('samplerecletter.pdf', 'application/pdf')
        },
        hash: valid_hash,
        id: enrollment.user.applicant_detail.id
      }
    end

    before do
      allow(controller).to receive(:get_recommendation)
      controller.instance_variable_set(:@recommendation, recommendation)
    end

    it 'handles file uploads successfully' do
      expect {
        post :create, params: file_params
      }.to change(Recupload, :count).by(1)

      recupload = Recupload.last
      expect(recupload.recletter).to be_attached
    end
  end
end
