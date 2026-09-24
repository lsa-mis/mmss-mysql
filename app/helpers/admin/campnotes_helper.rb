# frozen_string_literal: true

module Admin::CampnotesHelper
  # A note is shown while the current time falls in its open/close window — the per-record form of
  # the Campnote.currently_open scope used by the admin dashboard (app/views/admin/dashboard/_camp_notes.html.erb)
  # and the public navigation banner (app/views/admin/_camp_note.erb, rendered from layouts/_nav_links_for_auth).
  def admin_campnote_visible?(note)
    note.opendate.present? && note.closedate.present? && (note.opendate..note.closedate).cover?(Time.current)
  end

  # Alert/Notice plus the note's persisted type (older notes have other values), so the select
  # never clears the column.
  def admin_campnote_type_options(note)
    options = campnote_types.dup
    current = note.notetype
    options << [current.titleize, current] if current.present? && options.none? { |_label, value| value == current }
    options
  end

  def admin_campnote_type_badge(notetype)
    return admin_empty_value if notetype.blank?

    tag.span(notetype.to_s, class: notetype.to_s == 'alert' ? 'admin-badge-yellow' : 'admin-badge-blue')
  end
end
