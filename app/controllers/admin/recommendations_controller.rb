# frozen_string_literal: true

class Admin::RecommendationsController < Admin::BaseController
  before_action :set_recommendation, only: %i[show edit update destroy send_request_email]

  SORTS = {
    enrollment_id: 'applicant_details.lastname',
    email: 'recommendations.email',
    lastname: 'recommendations.lastname',
    firstname: 'recommendations.firstname',
    organization: 'recommendations.organization',
    city: 'recommendations.city',
    state: 'recommendations.state',
    country: 'recommendations.country',
    created_at: 'recommendations.created_at',
    updated_at: 'recommendations.updated_at'
  }.freeze

  BATCH_ACTIONS = { destroy: 'Delete selected' }.freeze

  CSV_EXPORT = Admin::CsvExport.define do
    column :id
    column('Applicant') { |recommendation| recommendation.enrollment.applicant_detail&.full_name }
    column('Applicant email') { |recommendation| recommendation.enrollment.user.email }
    column :email
    column :lastname
    column :firstname
    column :organization
    column :address1
    column :address2
    column :city
    column :state
    column :state_non_us
    column :postalcode
    column :country
    column :phone_number
    column :best_contact_time
    column('Letter received') { |recommendation| recommendation.recupload.present? }
    column :created_at
    column :updated_at
  end

  def index
    @filter = Admin::RecommendationsFilter.new(params[Admin::Filter::PARAM_KEY])
    relation = @filter.apply(base_relation)
    relation = apply_sort(relation, allowed: SORTS, default: :created_at, default_direction: :desc)

    respond_to do |format|
      format.html { @pagy, @recommendations = paginate(relation) }
      format.csv { send_csv(CSV_EXPORT, relation, filename: 'recommendations') }
    end
  end

  def show; end

  def new
    @recommendation = Recommendation.new
  end

  def create
    @recommendation = Recommendation.new(recommendation_params)

    if @recommendation.save
      redirect_to admin_recommendation_path(@recommendation), notice: 'Recommendation was successfully created.', status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @recommendation.update(recommendation_params)
      redirect_to admin_recommendation_path(@recommendation), notice: 'Recommendation was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @recommendation.destroy
    redirect_to admin_recommendations_path, notice: 'Recommendation was successfully deleted.', status: :see_other
  end

  def batch
    perform_batch_action(Recommendation.all, BATCH_ACTIONS, redirect_to_path: admin_recommendations_path)
  end

  # "Resend request" (the ActiveAdmin show page's mail link). Admin-only POST; the public GET on
  # RecommendationsController was removed in the foundation PR.
  def send_request_email
    RecommendationMailer.with(recommendation: @recommendation).request_email.deliver_now
    redirect_to admin_recommendation_path(@recommendation), notice: 'Recommendation request was sent!', status: :see_other
  end

  private

  def set_recommendation
    @recommendation = Recommendation.includes(:recupload, enrollment: %i[user applicant_detail]).find(params[:id])
  end

  def base_relation
    Recommendation.left_joins(enrollment: :applicant_detail).preload(:recupload, enrollment: %i[user applicant_detail])
  end

  def recommendation_params
    params.require(:recommendation).permit(:enrollment_id, :email, :lastname, :firstname, :organization, :address1, :address2,
                                           :city, :state, :state_non_us, :postalcode, :country, :phone_number, :best_contact_time)
  end
end
