# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Handle CSRF token errors gracefully with a helpful message
  rescue_from ActionController::InvalidAuthenticityToken do |_exception|
    # Check if user is authenticated - if not, session likely expired
    if user_signed_in? || admin_signed_in? || faculty_signed_in?
      # User is authenticated but CSRF token invalid - likely session expired
      flash[:alert] = "Your session expired. Please try submitting again. If the problem persists, please sign out and sign back in."
      redirect_back fallback_location: root_path
    else
      # User not authenticated - redirect to sign in
      flash[:alert] = "Your session expired. Please sign in again to continue."
      # Store the attempted URL to redirect after sign in
      store_location_for(:user, request.path) if request.get?
      redirect_to new_user_session_path
    end
  end

  def after_sign_in_path_for(_resource)
    if faculty_signed_in?
      faculty_path
    elsif admin_signed_in?
      admin_root_path
    else
      root_path
    end
  end

  # Set session creation time when user signs in
  # This is used by session_expires_at helper to calculate accurate expiry times
  before_action :set_session_creation_time

  private

  def set_session_creation_time
    # Only set if user is authenticated and session_created_at is not already set
    # This ensures we capture the actual sign-in time, not subsequent requests
    if (user_signed_in? || admin_signed_in? || faculty_signed_in?) && session[:session_created_at].nil?
      session[:session_created_at] = Time.current.to_i
    end
  end

end
