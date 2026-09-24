# frozen_string_literal: true

module Admin::CampnotesHelper
  # A note is shown in the public navigation while the current time falls in its open/close window
  # (see app/views/admin/_camp_note.erb).
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
