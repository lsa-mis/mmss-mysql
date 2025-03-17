ActiveAdmin.register Recupload do
  menu parent: 'Applicant Info', priority: 3

  config.filters = false
  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :letter, :authorname, :studentname, :recommendation_id, :rechash, :recletter

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :recommendation_id, label: 'Applicant Name', as: :select, collection: Recommendation.all.map { |reccup|
        [reccup.applicant_name, reccup.id]
      }.sort
      f.input :letter
      f.input :recletter, as: :file
      f.input :authorname
      f.input :studentname
    end
    f.actions
  end

  index do
    selectable_column
    actions
    column :recommendation_id, sortable: :recommendation_id do |ri|
      link_to ri.recommendation_id, admin_recommendation_path(ri.recommendation_id)
    end
    column 'Applicant' do |app|
      app.recommendation.enrollment.display_name
    end
    column 'Author/Reccommender' do |auth|
      auth.authorname
    end
    column :letter
    column 'Attached File' do |reclet|
      link_to reclet.recletter.filename, url_for(reclet.recletter), target: '_blank' if reclet.recletter.attached?
    end
  end

  show do
    attributes_table do
      row :id
      row :recommendation_id do |ri|
        link_to ri.recommendation_id, admin_recommendation_path(ri.recommendation_id)
      end
      row :studentname
      row :letter
      row :recletter do |rl|
        link_to rl.recletter.filename, url_for(rl.recletter), target: '_blank' if rl.recletter.attached?
      end
      row :authorname
    end
    active_admin_comments
  end
end
