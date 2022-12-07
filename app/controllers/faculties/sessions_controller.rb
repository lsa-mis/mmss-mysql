# frozen_string_literal: true

class Faculties::SessionsController < Devise::SessionsController

  # after_action :after_login

  # GET /resource/sign_in
   def new
     super
   end

  # POST /resource/sign_in
   def create
     super
   end

  # DELETE /resource/sign_out
   def destroy
     super
   end

   private

    def after_login
      if faculty_signed_in?
        uniqname = current_faculty.email.split('@').first
        unless Course.current_camp.pluck(:faculty_uniqname).uniq.compact.include?(uniqname)
          # flash.now[:alert] = "hell"
          # redirect_todestroy_faculty_session_path
          redirect_to(controller: 'faculties/sessions', action: 'destroy', method: :delete) and return
        end
      end
    end
end
