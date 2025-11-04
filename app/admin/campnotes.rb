# frozen_string_literal: true

ActiveAdmin.register Campnote do
  menu parent: 'Camp Setup'

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :note, :opendate, :closedate, :notetype
  #
  # or
  #
  # permit_params do
  #   permitted = [:note, :opendate, :closedate, :notetype]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  form do |f| # This is a formtastic form builder
    f.semantic_errors # shows errors on :base
    # f.inputs           # builds an input field for every attribute
    f.inputs do
      f.input :note
      f.input :opendate
      f.input :closedate
      f.input :notetype, as: :select, collection: campnote_types
    end
    f.actions         # adds the 'Submit' and 'Cancel' button
  end
  
end
