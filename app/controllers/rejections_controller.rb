# frozen_string_literal: true

class RejectionsController < InheritedResources::Base

  private

    def rejection_params
      params.require(:rejection).permit(:enrollment_id, :reason)
    end

end
