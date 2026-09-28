# frozen_string_literal: true

# Applicant Details: the personal / address / parent record each applicant fills in once. No
# destroy (ActiveAdmin had none; the applicant's account owns the record) and the owning user is
# fixed once the record exists — the public form never lets an applicant re-home it either.
class Admin::ApplicantDetailsController < Admin::BaseController
  before_action :set_applicant_detail, only: %i[show edit update]

  SCOPES = [
    Admin::Scope.new(:all, label: 'All', group: :application_status, default: true),
    Admin::Scope.new(:current_camp_enrolled, label: 'Current camp enrolled', group: :application_status)
  ].freeze

  SORTS = {
    fullname: 'applicant_details.lastname',
    email: 'users.email',
    us_citizen: 'applicant_details.us_citizen',
    birthdate: 'applicant_details.birthdate',
    shirt_size: 'applicant_details.shirt_size',
    city: 'applicant_details.city',
    state: 'applicant_details.state',
    postalcode: 'applicant_details.postalcode',
    country: 'applicant_details.country',
    created_at: 'applicant_details.created_at',
    updated_at: 'applicant_details.updated_at'
  }.freeze

  def index
    @filter = Admin::ApplicantDetailsFilter.new(params[Admin::Filter::PARAM_KEY])
    relation = @filter.apply(base_relation)
    @scope_counts = scope_counts(relation, SCOPES)
    relation = apply_scope(relation, SCOPES)
    relation = apply_sort(relation, allowed: SORTS, default: :fullname)
    relation = with_latest_enrollment_id(relation)
    @genders = gender_names

    respond_to do |format|
      format.html { @pagy, @applicant_details = paginate(relation) }
      format.csv { send_csv(csv_export, relation, filename: 'applicant_details') }
    end
  end

  def show
    @applications = @applicant_detail.user.enrollments.order(campyear: :desc, id: :desc)
  end

  def new
    # ?user_id= prefills the user picker (e.g. from a user's admin page); unknown ids are ignored.
    @applicant_detail = ApplicantDetail.new(user: User.find_by(id: params[:user_id].presence))
  end

  def create
    @applicant_detail = ApplicantDetail.new(applicant_detail_params(:user_id))

    if @applicant_detail.save
      redirect_to admin_applicant_detail_path(@applicant_detail), notice: 'Applicant detail was successfully created.',
                                                                  status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @applicant_detail.update(applicant_detail_params)
      redirect_to admin_applicant_detail_path(@applicant_detail), notice: 'Applicant detail was successfully updated.',
                                                                  status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_applicant_detail
    @applicant_detail = ApplicantDetail.includes(:user, :demographic).find(params[:id])
  end

  # users is an inner join (user_id is NOT NULL with a foreign key); the `current_camp_enrolled`
  # scope joins it again, which ActiveRecord folds into the same join.
  def base_relation
    ApplicantDetail.joins(:user).preload(:user, :demographic)
  end

  # The email column links to the applicant's latest application; computing its id in SQL avoids
  # loading every enrollment of every row. Added after scope_counts (see Admin::BalanceDueQuery).
  def with_latest_enrollment_id(relation)
    relation.select('applicant_details.*',
                    '(SELECT MAX(enrollments.id) FROM enrollments WHERE enrollments.user_id = applicant_details.user_id) AS latest_enrollment_id')
  end

  # `gender` stores the Gender id as a string; one lookup for the whole page instead of a query
  # per row (ApplicantDetail#gender_name).
  def gender_names
    Gender.pluck(:id, :name).to_h { |id, name| [id.to_s, name] }
  end

  ATTRIBUTES = %i[
    firstname middlename lastname gender us_citizen demographic_id demographic_other
    birthdate diet_restrictions shirt_size address1 address2 city state state_non_us
    postalcode country phone parentname parentaddress1 parentaddress2 parentcity parentstate
    parentstate_non_us parentzip parentcountry parentphone parentworkphone parentemail
  ].freeze

  # user_id is only accepted on create (see class comment).
  def applicant_detail_params(*extra)
    params.require(:applicant_detail).permit(*ATTRIBUTES, *extra)
  end

  def csv_export
    Admin::CsvExport.define do
      column :lastname
      column :firstname
      column('email') { |detail| detail.user.email }
      column('demographic') { |detail| detail.formatted_demographic }
      column :us_citizen
      column :birthdate
      column :diet_restrictions
      column :shirt_size
      column :address1
      column :address2
      column :city
      column :state
      column :state_non_us
      column :postalcode
      column :country
      column :phone
      column :parentname
      column :parentphone
      column :parentworkphone
      column :parentemail
      column :created_at
      column :updated_at
    end
  end
end
