# frozen_string_literal: true

# Value formatting shared by admin tables, attribute lists and dashboard panels.
module Admin::FormatHelper
  EMPTY = '—'

  # Formats any cell/attribute value for display. Strings are escaped; html_safe strings and
  # ActiveSupport::SafeBuffer (e.g. from link_to) are rendered as-is.
  def admin_format_value(value)
    case value
    when nil, '' then admin_empty_value
    when ActiveSupport::SafeBuffer then value
    when true, false then admin_boolean(value)
    when Money then value.format
    when ActiveSupport::TimeWithZone, Time, DateTime then admin_datetime(value)
    when Date then admin_date(value)
    when ActiveRecord::Base then value.try(:display_name) || value.try(:name) || value.to_s
    when Array then value.map { |item| admin_format_value(item) }.then { |items| safe_join(items, ', ') }
    when ActiveStorage::Attached::One then admin_attachment_link(value)
    else value.to_s
    end
  end

  def admin_empty_value
    tag.span(EMPTY, class: 'text-slate-400')
  end

  def admin_boolean(value)
    value ? tag.span('Yes', class: 'admin-badge-green') : tag.span('No', class: 'admin-badge-gray')
  end

  def admin_date(value)
    value.blank? ? admin_empty_value : value.strftime('%b %-d, %Y')
  end

  def admin_datetime(value)
    value.blank? ? admin_empty_value : value.in_time_zone.strftime('%b %-d, %Y %-l:%M %p')
  end

  # Cents (Integer or numeric String) to a currency string, matching the ActiveAdmin views.
  def admin_money_from_cents(cents)
    return admin_empty_value if cents.blank?

    humanized_money_with_symbol(cents.to_f / 100)
  end

  def admin_attachment_link(attachment, text: nil)
    return admin_empty_value unless attachment.attached?

    link_to text || attachment.filename.to_s, url_for(attachment), target: '_blank', rel: 'noopener',
                                                                    class: 'admin-btn-link'
  end

  # Colour-coded status badge. Known application/offer statuses get a matching colour; anything
  # else is grey.
  def admin_status_badge(status)
    return admin_empty_value if status.blank?

    colour = case status.to_s
             when 'enrolled', 'accepted', 'awarded', 'open', 'offer accepted' then 'green'
             when 'offered', 'application complete', 'pending', 'submitted' then 'blue'
             when 'waitlisted' then 'yellow'
             when 'withdrawn', 'rejected', 'declined', 'offer declined', 'closed' then 'red'
             else 'gray'
             end
    tag.span(status.to_s, class: "admin-badge-#{colour}")
  end
end
