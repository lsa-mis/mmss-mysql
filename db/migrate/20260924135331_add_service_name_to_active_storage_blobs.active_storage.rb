# This migration comes from active_storage (originally 20190112182829)
#
# In this app the column already exists: 20190926163519_create_active_storage_tables was
# edited to include service_name, so `up` is a no-op and `down` must not remove a column
# that migration owns. The file is kept so `rails active_storage:update` does not copy it again.
class AddServiceNameToActiveStorageBlobs < ActiveRecord::Migration[6.0]
  def up
    return unless table_exists?(:active_storage_blobs)

    unless column_exists?(:active_storage_blobs, :service_name)
      add_column :active_storage_blobs, :service_name, :string

      if configured_service = ActiveStorage::Blob.service.name
        ActiveStorage::Blob.unscoped.update_all(service_name: configured_service)
      end

      change_column :active_storage_blobs, :service_name, :string, null: false
    end
  end

  def down
    # Intentionally a no-op: service_name predates this migration (see above).
  end
end
