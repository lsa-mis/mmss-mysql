# frozen_string_literal: true

# Adds admin comments (Admin::Comment) to a model. Include it and render the
# `admin/comments/comments` partial on the record's admin show page.
module AdminCommentable
  extend ActiveSupport::Concern

  included do
    has_many :admin_comments, class_name: 'Admin::Comment', as: :resource, dependent: :destroy
  end
end
