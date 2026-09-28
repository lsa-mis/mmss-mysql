# frozen_string_literal: true

# Applicant accounts (the Devise `User` model).
class Admin::UsersController < Admin::BaseController
  include Admin::DeviseAccountParams

  before_action :set_user, only: %i[show edit update destroy]

  SORTS = {
    id: 'users.id',
    email: 'users.email',
    current_sign_in_at: 'users.current_sign_in_at',
    sign_in_count: 'users.sign_in_count',
    created_at: 'users.created_at'
  }.freeze

  BATCH_ACTIONS = { destroy: 'Delete selected' }.freeze

  def index
    @filter = Admin::UsersFilter.new(params[Admin::Filter::PARAM_KEY])
    relation = @filter.apply(User.all)
    relation = apply_sort(relation, allowed: SORTS, default: :id, default_direction: :desc)

    respond_to do |format|
      format.html { @pagy, @users = paginate(relation) }
      format.csv { send_csv(csv_export, relation, filename: 'users') }
    end
  end

  def show
    @enrollments = @user.enrollments.order(campyear: :desc)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(account_params(:user))

    if @user.save
      redirect_to admin_user_path(@user), notice: 'User was successfully created.', status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @user.update(account_params_for_update(:user))
      redirect_to admin_user_path(@user), notice: 'User was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @user.destroy
      redirect_to admin_users_path, notice: 'User was successfully deleted.', status: :see_other
    else
      redirect_to admin_user_path(@user), alert: "User could not be deleted: #{@user.errors.full_messages.to_sentence}",
                                          status: :see_other
    end
  end

  def batch
    perform_batch_action(User.all, BATCH_ACTIONS, redirect_to_path: admin_users_path)
  end

  private

  def set_user
    @user = User.includes(:applicant_detail).find(params[:id])
  end

  # Users with payments or payment requests refuse to be destroyed (see User); report them
  # instead of failing the whole batch.
  def batch_destroy(records)
    destroyed, kept = records.to_a.partition(&:destroy)
    notice = "Deleted #{destroyed.size} #{'user'.pluralize(destroyed.size)}."
    if kept.any?
      notice += " Skipped #{kept.size} with payments or payment requests: #{kept.map(&:email).to_sentence}."
    end
    notice
  end

  def csv_export
    Admin::CsvExport.define do
      column :id
      column :email
      column :current_sign_in_at
      column :last_sign_in_at
      column :sign_in_count
      column :created_at
      column :updated_at
    end
  end
end
