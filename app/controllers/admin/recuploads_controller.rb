# frozen_string_literal: true

# Recuploads = recommendation letters uploaded by recommenders (public RecuploadsController#new /
# #create). Admins can also enter a letter on the recommender's behalf here.
class Admin::RecuploadsController < Admin::BaseController
  before_action :set_recupload, only: %i[show edit update destroy]

  SORTS = {
    recommendation_id: 'recuploads.recommendation_id',
    applicant: 'applicant_details.lastname',
    authorname: 'recuploads.authorname',
    studentname: 'recuploads.studentname',
    created_at: 'recuploads.created_at',
    updated_at: 'recuploads.updated_at'
  }.freeze

  BATCH_ACTIONS = { destroy: 'Delete selected' }.freeze

  CSV_EXPORT = Admin::CsvExport.define do
    column :id
    column :recommendation_id
    column('Applicant') { |recupload| recupload.recommendation.enrollment.applicant_detail&.full_name }
    column('Applicant email') { |recupload| recupload.recommendation.enrollment.user.email }
    column :authorname
    column :studentname
    column('Letter') { |recupload| recupload.letter }
    column('Attached file') { |recupload| recupload.recletter.filename.to_s if recupload.recletter.attached? }
    column :created_at
    column :updated_at
  end

  def index
    @filter = Admin::RecuploadsFilter.new(params[Admin::Filter::PARAM_KEY])
    relation = @filter.apply(base_relation)
    relation = apply_sort(relation, allowed: SORTS, default: :created_at, default_direction: :desc)

    respond_to do |format|
      format.html { @pagy, @recuploads = paginate(relation) }
      format.csv { send_csv(CSV_EXPORT, relation, filename: 'recuploads') }
    end
  end

  def show; end

  def new
    @recupload = Recupload.new
  end

  def create
    @recupload = Recupload.new(recupload_params)

    if @recupload.save
      redirect_to admin_recupload_path(@recupload), notice: 'Recupload was successfully created.', status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @recupload.update(recupload_params)
      redirect_to admin_recupload_path(@recupload), notice: 'Recupload was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @recupload.destroy
    redirect_to admin_recuploads_path, notice: 'Recupload was successfully deleted.', status: :see_other
  end

  def batch
    perform_batch_action(Recupload.all, BATCH_ACTIONS, redirect_to_path: admin_recuploads_path)
  end

  private

  def set_recupload
    @recupload = Recupload.with_attached_recletter.includes(recommendation: { enrollment: %i[user applicant_detail] }).find(params[:id])
  end

  def base_relation
    Recupload.left_joins(recommendation: { enrollment: :applicant_detail })
             .with_attached_recletter
             .preload(recommendation: { enrollment: %i[user applicant_detail] })
  end

  def recupload_params
    params.require(:recupload).permit(:recommendation_id, :letter, :recletter, :authorname, :studentname)
  end
end
