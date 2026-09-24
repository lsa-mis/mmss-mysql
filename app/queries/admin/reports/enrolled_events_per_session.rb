# frozen_string_literal: true

class Admin::Reports::EnrolledEventsPerSession < Admin::Reports::Base
  include Admin::Reports::CountryColumn

  self.label = 'Events per Session'
  self.description = 'Activities chosen by enrolled students for the camp year, per accepted session: one row per ' \
                     'student and activity with room mate request and home town.'
  self.csv_title = 'events_per_session_for_enrolled'
  self.sql = <<~SQL
    SELECT ad.country, a.description AS 'Event Activity',
      co.description AS Session,
      ad.lastname,
      ad.firstname,
      u.email,
      e.room_mate_request,
      ad.city,
      ad.state,
      e.id
      FROM session_assignments AS sa
      JOIN enrollments AS e ON e.id = sa.enrollment_id
      JOIN enrollment_activities AS ea ON ea.enrollment_id = sa.enrollment_id
      JOIN activities as a ON a.id = ea.activity_id AND a.camp_occurrence_id = sa.camp_occurrence_id
      JOIN camp_occurrences AS co ON co.id = a.camp_occurrence_id
      JOIN applicant_details AS ad ON ad.user_id = e.user_id
      JOIN users AS u ON u.id = ad.user_id
      WHERE sa.enrollment_id IN (
        SELECT id
        FROM enrollments
        WHERE application_status = 'enrolled' AND campyear = :camp_year
      ) AND sa.offer_status = 'accepted'
      ORDER BY co.description, a.description, ad.lastname, e.id
  SQL
end
