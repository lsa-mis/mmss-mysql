# frozen_string_literal: true

# ActiveAdmin is gone; its comments table now belongs to Admin::Comment. Existing rows (including
# the ActiveAdmin `namespace` values 'admin' / 'legacy_admin') are kept as they are; the column
# is documented in app/models/admin/comment.rb.
class RenameActiveAdminCommentsToAdminComments < ActiveRecord::Migration[8.1]
  def change
    rename_table :active_admin_comments, :admin_comments
  end
end
