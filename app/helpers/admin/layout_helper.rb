# frozen_string_literal: true

module Admin::LayoutHelper
  def admin_menu_groups = Admin::Menu.groups

  def admin_menu_item_path(item) = public_send(item.route)

  def admin_menu_item_active?(item)
    path = admin_menu_item_path(item)
    item.match == :exact ? request.path == path : request.path.start_with?(path)
  end

  FLASH_STYLES = {
    'notice' => 'border-green-200 bg-green-50 text-green-800',
    'success' => 'border-green-200 bg-green-50 text-green-800',
    'alert' => 'border-amber-200 bg-amber-50 text-amber-900',
    'error' => 'border-red-200 bg-red-50 text-red-800'
  }.freeze

  def admin_flash_class(type)
    FLASH_STYLES.fetch(type.to_s, 'border-slate-200 bg-white text-slate-800')
  end
end
