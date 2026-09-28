# frozen_string_literal: true

# Admin accounts (the Devise `Admin` model that signs in to this admin).
class Admin::AdminsController < Admin::BaseController
  include Admin::DeviseAccountParams

  before_action :set_admin, only: %i[show edit update destroy unlock]

  SORTS = {
    id: 'admins.id',
    email: 'admins.email',
    current_sign_in_at: 'admins.current_sign_in_at',
    sign_in_count: 'admins.sign_in_count',
    created_at: 'admins.created_at'
  }.freeze

  BATCH_ACTIONS = { destroy: 'Delete selected' }.freeze

  def index
    relation = apply_sort(Admin.all, allowed: SORTS, default: :id, default_direction: :desc)

    respond_to do |format|
      format.html { @pagy, @admins = paginate(relation) }
      format.csv { send_csv(csv_export, relation, filename: 'admins') }
    end
  end

  def show; end

  def new
    @admin = Admin.new
  end

  def create
    @admin = Admin.new(account_params(:admin))

    if @admin.save
      redirect_to admin_admin_path(@admin), notice: 'Admin was successfully created.', status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @admin.update(account_params_for_update(:admin))
      redirect_to admin_admin_path(@admin), notice: 'Admin was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @admin == current_admin
      redirect_to admin_admin_path(@admin), alert: 'You cannot delete the account you are signed in with.', status: :see_other
    else
      @admin.destroy
      redirect_to admin_admins_path, notice: 'Admin was successfully deleted.', status: :see_other
    end
  end

  # Devise `lockable`: clears the lock set after too many failed sign-in attempts.
  def unlock
    @admin.unlock_access!
    redirect_to admin_admin_path(@admin), notice: 'Admin account was unlocked.', status: :see_other
  end

  def batch
    perform_batch_action(Admin.all, BATCH_ACTIONS, redirect_to_path: admin_admins_path)
  end

  private

  def set_admin
    @admin = Admin.find(params[:id])
  end

  # Never let a batch delete remove the signed-in admin.
  def batch_destroy(records)
    super(records.where.not(id: current_admin.id))
  end

  def csv_export
    Admin::CsvExport.define do
      column :id
      column :email
      column :current_sign_in_at
      column :last_sign_in_at
      column :sign_in_count
      column :locked_at
      column :created_at
      column :updated_at
    end
  end
end
