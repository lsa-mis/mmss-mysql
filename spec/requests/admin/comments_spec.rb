# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin comments', type: :request do
  let(:admin) { create(:admin) }
  let(:enrollment) { create(:enrollment, user: create(:user, :with_applicant_detail)) }

  before { sign_in admin }

  it 'adds a comment to a commentable record and shows it on the show page' do
    post admin_comments_path, params: { resource_type: 'Enrollment', resource_id: enrollment.id, admin_comment: { body: 'Called the parent.' } },
                              headers: { 'HTTP_REFERER' => admin_application_path(enrollment) }

    expect(response).to redirect_to(admin_application_path(enrollment))
    comment = Admin::Comment.last
    expect(comment.body).to eq('Called the parent.')
    expect(comment.author).to eq(admin)
    expect(comment.resource).to eq(enrollment)
    expect(comment.namespace).to eq('admin')

    follow_redirect!
    expect(response.body).to include('Called the parent.')
    expect(response.body).to include(admin.email)
  end

  it 'rejects blank comments' do
    expect do
      post admin_comments_path, params: { resource_type: 'Enrollment', resource_id: enrollment.id, admin_comment: { body: '' } }
    end.not_to change(Admin::Comment, :count)

    expect(response).to redirect_to(admin_application_path(enrollment))
    expect(flash[:alert]).to include("Body can't be blank")
  end

  it 'refuses to comment on models that are not commentable' do
    post admin_comments_path, params: { resource_type: 'Admin', resource_id: admin.id, admin_comment: { body: 'nope' } }

    expect(response).to redirect_to(admin_root_path)
    expect(Admin::Comment.count).to eq(0)
  end

  it 'reads pre-existing ActiveAdmin comments from the same table' do
    ActiveRecord::Base.connection.execute(<<~SQL.squish)
      INSERT INTO active_admin_comments (namespace, body, resource_type, resource_id, author_type, author_id, created_at, updated_at)
      VALUES ('admin', 'Legacy note', 'Enrollment', #{enrollment.id}, 'Admin', #{admin.id}, NOW(), NOW())
    SQL

    get admin_application_path(enrollment)

    expect(response.body).to include('Legacy note')
    expect(enrollment.admin_comments.count).to eq(1)
  end

  it 'deletes a comment' do
    comment = enrollment.admin_comments.create!(body: 'temp', author: admin)

    delete admin_comment_path(comment)

    expect(response).to redirect_to(admin_comments_path)
    expect(Admin::Comment.exists?(comment.id)).to be(false)
  end

  it 'lists all comments' do
    enrollment.admin_comments.create!(body: 'first note', author: admin)

    get admin_comments_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('first note')
    expect(response.body).to include('Enrollment')
  end
end
