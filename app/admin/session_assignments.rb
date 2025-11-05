# frozen_string_literal: true

ActiveAdmin.register SessionAssignment do
  menu parent: 'Applicant Info', priority: 1

  permit_params :enrollment_id, :camp_occurrence_id, :offer_status

  scope :current_year_session_assignments, default: true, label: 'Current years Session Assignments'
  scope :all

  scope :accepted, group: :offer_status

  form do |f|
    f.inputs do
      f.input :enrollment_id, as: :select, collection: Enrollment.current_camp_year_applications.map { |enrol|
        [enrol.display_name.downcase, enrol.id]
      }.sort
      f.input :camp_occurrence_id, label: 'Session', as: :select, collection: CampOccurrence.active.no_any_session
      f.input :offer_status, as: :select, collection: %w[accepted declined]
    end
    f.actions
  end

  index do
    selectable_column
    actions
    column('Enrollment') { |sa| link_to sa.enrollment.display_name, admin_application_path(sa.enrollment_id) }
    column 'Session', &:camp_occurrence
    column :created_at
    column :updated_at
    column :offer_status
  end

  show do
    attributes_table do
      row('Enrollment') { |sa| link_to sa.enrollment.user.email, admin_application_path(sa.enrollment_id) }
      row 'Session', &:camp_occurrence
      row :created_at
      row :updated_at
      row :offer_status
    end
    active_admin_comments
  end

  filter :enrollment_id, as: :select, collection: proc {
    Enrollment.current_camp_year_applications.map { |enrol|
      [enrol.display_name.downcase, enrol.id]
    }.sort
  }
  filter :camp_occurrence_id, label: 'Session', as: :select, collection: -> { CampOccurrence.active.no_any_session }
  filter :offer_status, as: :select

  csv do
    column 'Name' do |sa|
      sa.enrollment.applicant_detail.full_name
    end
    column 'email' do |sa|
      sa.enrollment.user.email
    end
    column 'Session' do |sa|
      sa.camp_occurrence.display_name
    end
  end
end
