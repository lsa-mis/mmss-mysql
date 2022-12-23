ActiveAdmin.register_page "Reports" do
  menu parent: 'Dashboard', priority: 1

  content title: "Reports" do

    columns do
      panel "queries" do
        ul do
          li link_to "report - All Complete Applications", admin_reports_all_complete_apps_path
          li link_to "report - Registered but not Applied", admin_reports_registered_but_not_applied_path
          li link_to "report - Pending Course Assignments with Students", admin_reports_pending_course_assignments_with_students_path
          li link_to "report - Accepted Course Assignments with Students", admin_reports_accepted_course_assignments_with_students_path
          li link_to "report - Demographic Report", admin_reports_demographic_report_path
          li link_to "report - Complete Application with Course Preferences", admin_reports_complete_applications_with_course_preferences_path
          li link_to "report - Waitlisted Application with Course Preferences", admin_reports_waitlisted_applications_with_course_preferences_path
        end
        text_node "----- ENROLLED USERS -----".html_safe
        ul do
          li link_to "report - Enrolled with Addresses", admin_reports_enrolled_with_addresses_path
          li link_to "report - Events per Session", admin_reports_enrolled_events_per_session_path
          li link_to "report - Dorm by State", admin_reports_enrolled_dorm_by_state_path
          li link_to "report - Enrolled Students with Sessions and Courses", admin_reports_enrolled_with_sessions_and_courses_path
          li link_to "report - Enrolled Students with Sessions and T-Shirt size", admin_reports_enrolled_with_sessions_and_tshirt_path
          li link_to "report - Course Assignments", admin_reports_course_assignments_path
          li link_to "report - Enrolled Students with Covid Verification", admin_reports_enrolled_with_covid_verification_path
          li link_to "report - Enrolled with Addresses, Birthdate, Gender, Graduation Year", admin_reports_enrolled_with_addresses_and_more_path
          li link_to "report - Enrolled for More than One Session", admin_reports_enrolled_for_more_than_one_session_path

        end
      end
    end
  end # content

  controller do
    
    def demographic_report
      query = "SELECT ad.country,
      (CASE WHEN ad.gender = '' THEN NULL ELSE 
      (SELECT genders.name FROM genders WHERE CAST(ad.gender AS UNSIGNED) = genders.id) END) as gender,
      e.year_in_school,
      (CASE WHEN ad.demographic = '' THEN NULL ELSE 
      (SELECT demographics.name FROM demographics WHERE CAST(ad.demographic AS UNSIGNED) = demographics.id) END) AS demographic,
      e.international
      FROM enrollments AS e 
      LEFT JOIN users AS u ON e.user_id = u.id
      LEFT JOIN applicant_details AS ad ON ad.user_id = e.user_id
      WHERE e.application_status = 'enrolled' AND e.campyear = #{CampConfiguration.active.last.camp_year} ORDER BY country, gender, year_in_school"
      title = "demographic"

      data = data_to_csv_demographic(query, title)
      respond_to do |format|
        format.html { send_data data, filename: "MMSS-report-#{title}-#{DateTime.now.strftime('%-d-%-m-%Y')}.csv"}
      end
    end

    def registered_but_not_applied
      query = "SELECT u.id, u.email, CONCAT(REPLACE(ad.firstname, ',', ' '), ' ', REPLACE(ad.lastname, ',', ' ')) AS name, DATE_FORMAT(u.current_sign_in_at, '%Y-%m-%d') AS 'Last user login', DATE_FORMAT(ad.created_at, '%Y-%m-%d') AS 'Applicant Details created' 
      FROM users AS u
      JOIN applicant_details AS ad on u.id = ad.user_id 
      WHERE ad.user_id NOT IN (SELECT e.user_id FROM enrollments AS e WHERE e.campyear = (SELECT cc.camp_year FROM camp_configurations AS cc WHERE cc.active = true)) ORDER BY ad.created_at DESC, u.current_sign_in_at DESC"
      title = "registered_but_not_applied"

      data = data_to_csv(query, title)
      respond_to do |format|
        format.html { send_data data, filename: "MMSS-report-#{title}-#{DateTime.now.strftime('%-d-%-m-%Y')}.csv"}
      end
    end

    def all_complete_apps
      query = "SELECT DATE_FORMAT(e.updated_at, '%Y-%m-%d') AS 'Last Update', CONCAT(REPLACE(ad.firstname, ',', ' '), ' ', REPLACE(ad.lastname, ',', ' ')) AS name, u.email,
      (CASE WHEN ad.gender = '' THEN NULL ELSE 
      (SELECT genders.name FROM genders WHERE CAST(ad.gender AS UNSIGNED) = genders.id) END) as gender, 
      ad.us_citizen as us_citizen,
      (CASE WHEN ad.demographic = '' THEN NULL ELSE 
      (SELECT demographics.name FROM demographics WHERE CAST(ad.demographic AS UNSIGNED) = demographics.id) END) AS demographic,
      ad.birthdate as birthdate, ad.diet_restrictions as diet_restrictions,
      ad.shirt_size as shirt_size, CONCAT(ad.address1, ' ', ad.address2, ' ', ad.city, ' ', 
      ad.state, ' ', ad.state_non_us, ' ', ad.postalcode, ' ', ad.country) AS address,
      ad.phone as phone, ad.parentname as parentname,
      CONCAT(ad.parentaddress1, ' ', ad.parentaddress2, ' ', ad.parentcity, ' ', ad.parentstate, ' ',
      ad.parentstate_non_us, ' ', ad.parentzip, ' ', ad.parentcountry) AS parent_address,
      ad.parentphone as parentphone, ad.parentworkphone as parentworkphone, ad.parentemail as parentemail,
      e.user_id as user_id, e.international as international, e.high_school_name as high_school_name,
      CONCAT(e.high_school_address1, ' ', e.high_school_address2, ' ',
      e.high_school_city, ' ', e.high_school_state, ' ',
      e.high_school_non_us, ' ', e.high_school_postalcode, ' ',
      e.high_school_country) AS high_school_address, e.year_in_school as year_in_school,
      e.anticipated_graduation_year as anticipated_graduation_year, e.room_mate_request as room_mate_request,
      e.personal_statement as personal_statement, e.notes as notes,
      e.application_status as application_status, e.offer_status as offer_status,
      r.email AS recommender_email, CONCAT(REPLACE(r.lastname, ',', ' '), ' ', REPLACE(r.firstname, ',', ' ')) AS recommender_name, r.organization AS recommender_organization,
      (fa.amount_cents / 100) AS fin_aid_amount, fa.source AS fin_aid_source, fa.note AS fin_aid_note, fa.status AS fin_aid_status
      FROM enrollments AS e
      LEFT JOIN users AS u ON e.user_id = u.id
      LEFT JOIN applicant_details AS ad ON ad.user_id = e.user_id
      LEFT JOIN recommendations AS r ON r.enrollment_id = e.id
      LEFT JOIN financial_aids AS fa ON fa.enrollment_id = e.id
      WHERE e.application_status = 'application complete' AND e.campyear = #{CampConfiguration.active.last.camp_year} ORDER BY name"
      title = "all_complete_applications"

      data = data_to_csv(query, title)
      respond_to do |format|
        format.html { send_data data, filename: "MMSS-report-#{title}-#{DateTime.now.strftime('%-d-%-m-%Y')}.csv"}
      end
      
    end

    def enrolled_with_addresses
      query = "Select CONCAT(REPLACE(ad.firstname, ',', ' '), ' ', REPLACE(ad.lastname, ',', ' ')) AS name, REPLACE(ad.lastname, ',', ' ') AS lastname, REPLACE(ad.firstname, ',', ' ') AS firstname, u.email,
              ad.address1, ad.address2, ad.city, ad.state, ad.state_non_us, ad.postalcode, ad.country 
              FROM enrollments AS e 
              LEFT JOIN users AS u ON e.user_id = u.id
              JOIN applicant_details AS ad ON ad.user_id = e.user_id
              WHERE e.application_status = 'enrolled' AND e.campyear = #{CampConfiguration.active.last.camp_year} ORDER BY name"
      title = "enrolled_with_addresses"

      data = data_to_csv(query, title)
      respond_to do |format|
        format.html { send_data data, filename: "MMSS-report-#{title}-#{DateTime.now.strftime('%-d-%-m-%Y')}.csv"}
      end
    end

    def pending_course_assignments_with_students
      query = "SELECT co.description, cor.title, en.user_id, REPLACE(ad.lastname, ',', ' ') AS lastname, REPLACE(ad.firstname, ',', ' ') AS firstname, u.email
      FROM course_assignments ca 
      JOIN enrollments en ON ca.enrollment_id = en.id 
      JOIN applicant_details AS ad ON ad.user_id = en.user_id 
      JOIN courses AS cor ON ca.course_id = cor.id 
      JOIN camp_occurrences AS co ON cor.camp_occurrence_id = co.id
      LEFT JOIN users AS u ON en.user_id = u.id
      WHERE en.campyear = #{CampConfiguration.active.last.camp_year}
      ORDER BY co.description, cor.title"
      title = "pending_course_assignments_with_students"

      data = data_to_csv(query, title)
      respond_to do |format|
        format.html { send_data data, filename: "MMSS-report-#{title}-#{DateTime.now.strftime('%-d-%-m-%Y')}.csv"}
      end
    end

    def accepted_course_assignments_with_students
      query = "SELECT co.description, cor.title, en.user_id, REPLACE(ad.lastname, ',', ' ') AS lastname, REPLACE(ad.firstname, ',', ' ') AS firstname, u.email
      FROM course_assignments ca 
      JOIN enrollments en ON ca.enrollment_id = en.id 
      JOIN applicant_details AS ad ON ad.user_id = en.user_id 
      JOIN courses AS cor ON ca.course_id = cor.id 
      JOIN camp_occurrences AS co ON cor.camp_occurrence_id = co.id
      LEFT JOIN users AS u ON en.user_id = u.id
      WHERE en.campyear = #{CampConfiguration.active.last.camp_year} AND en.offer_status = 'accepted'
      ORDER BY co.description, cor.title"
      title = "accepted_course_assignments_with_students"

      data = data_to_csv(query, title)
      respond_to do |format|
        format.html { send_data data, filename: "MMSS-report-#{title}-#{DateTime.now.strftime('%-d-%-m-%Y')}.csv"}
      end
    end

    def events_per_session_for_enrolled
      query = "SELECT ad.country, a.description AS 'Event Activity', co.description AS Session, ad.lastname, ad.firstname, u.email, e.room_mate_request, ad.city, ad.state, e.id
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
        WHERE application_status = 'enrolled' AND campyear = #{CampConfiguration.active.last.camp_year}
      ) AND sa.offer_status = 'accepted'
      ORDER BY co.description, a.description, ad.lastname, e.id"
      title = "events_per_session_for_enrolled"

      data = data_to_csv_with_country(query, title)
      respond_to do |format|
        format.html { send_data data, filename: "MMSS-report-#{title}-#{DateTime.now.strftime('%-d-%-m-%Y')}.csv"}
      end
    end

    def dorm_by_state
      query = "SELECT ad.country, co.description AS Session, a.description AS 'Event Activity', ad.lastname, ad.firstname, u.email, ad.city, ad.state,
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
        WHERE application_status = 'enrolled' AND campyear = #{CampConfiguration.active.last.camp_year}
      ) AND sa.offer_status = 'accepted' AND a.description LIKE ('Dormitory%')
      ORDER BY co.description, ad.state"
      title = "dorm_by_state"

      data = data_to_csv_with_country(query, title)
      respond_to do |format|
        format.html { send_data data, filename: "MMSS-report-#{title}-#{DateTime.now.strftime('%-d-%-m-%Y')}.csv"}
      end
    end

    def complete_applications_with_course_preferences
      query = "SELECT u.email, ad.lastname, ad.firstname, cp.ranking, c.title, co.description
      FROM enrollments AS e
      JOIN course_preferences AS cp ON cp.enrollment_id = e.id
      JOIN courses AS c ON cp.course_id = c.id
      JOIN camp_occurrences AS co ON c.camp_occurrence_id = co.id
      JOIN applicant_details AS ad ON e.user_id = ad.user_id
      JOIN users AS u ON u.id = e.user_id
      WHERE campyear = #{CampConfiguration.active.last.camp_year} AND application_status = 'application complete' AND (offer_status = '' OR offer_status IS NULL)
      ORDER BY e.id, co.description, cp.ranking"
      title = "complete_applications_with_course_preferences"

      data = data_to_csv(query, title)
      respond_to do |format|
        format.html { send_data data, filename: "MMSS-report-#{title}-#{DateTime.now.strftime('%-d-%-m-%Y')}.csv"}
      end
    end

    def waitlisted_applications_with_course_preferences
      query = "SELECT u.email, ad.lastname, ad.firstname, cp.ranking, c.title, co.description
      FROM enrollments AS e
      JOIN course_preferences AS cp ON cp.enrollment_id = e.id
      JOIN courses AS c ON cp.course_id = c.id
      JOIN camp_occurrences AS co ON c.camp_occurrence_id = co.id
      JOIN applicant_details AS ad ON e.user_id = ad.user_id
      JOIN users AS u ON u.id = e.user_id
      WHERE campyear = #{CampConfiguration.active.last.camp_year} AND application_status = 'waitlisted'
      ORDER BY e.id, co.description, cp.ranking"
      title = "waitlisted_applications_with_course_preferences"

      data = data_to_csv(query, title)
      respond_to do |format|
        format.html { send_data data, filename: "MMSS-report-#{title}-#{DateTime.now.strftime('%-d-%-m-%Y')}.csv"}
      end
    end

    def enrolled_with_sessions_and_courses
      query = "SELECT ad.country, co.description AS session, cor.title AS course, en.user_id, REPLACE(ad.lastname, ',', ' ') AS lastname, REPLACE(ad.firstname, ',', ' ') AS firstname, u.email,
      en.year_in_school, ad.state
      FROM course_assignments ca 
      JOIN enrollments en ON ca.enrollment_id = en.id 
      JOIN applicant_details AS ad ON ad.user_id = en.user_id 
      JOIN courses AS cor ON ca.course_id = cor.id 
      JOIN camp_occurrences AS co ON cor.camp_occurrence_id = co.id
      LEFT JOIN users AS u ON en.user_id = u.id
      WHERE en.campyear = #{CampConfiguration.active.last.camp_year} AND en.application_status = 'enrolled'
      ORDER BY co.description, cor.title"
      title = "enrolled_students_with_sessions_and_courses"

      data = data_to_csv_with_country(query, title)
      respond_to do |format|
        format.html { send_data data, filename: "MMSS-report-#{title}-#{DateTime.now.strftime('%-d-%-m-%Y')}.csv"}
      end
    end

    def enrolled_for_more_than_one_session
      hash_with_ids = SessionAssignment.accepted.group(:enrollment_id).having('count(*) > 1').size
      enroll_ids = hash_with_ids.keys.join(", ")

      query = "SELECT ad.country,  en.user_id, REPLACE(ad.lastname, ',', ' ') AS lastname, REPLACE(ad.firstname, ',', ' ') AS firstname, u.email, co.description AS session, cor.title AS course,
      en.year_in_school, ad.state
      FROM course_assignments ca 
      JOIN enrollments en ON ca.enrollment_id = en.id 
      JOIN applicant_details AS ad ON ad.user_id = en.user_id 
      JOIN courses AS cor ON ca.course_id = cor.id 
      JOIN camp_occurrences AS co ON cor.camp_occurrence_id = co.id
      LEFT JOIN users AS u ON en.user_id = u.id
      WHERE en.campyear = #{CampConfiguration.active.last.camp_year} AND en.application_status = 'enrolled' and en.id IN (#{enroll_ids})
      ORDER BY u.email, co.description"

      title = "enrolled_for_more_than_one_session"

      data = data_to_csv_with_country(query, title)
      respond_to do |format|
        format.html { send_data data, filename: "MMSS-report-#{title}-#{DateTime.now.strftime('%-d-%-m-%Y')}.csv"}
      end
    end

    def enrolled_with_sessions_and_tshirt
      query = "SELECT co.description AS session, en.user_id, REPLACE(ad.lastname, ',', ' ') AS lastname, REPLACE(ad.firstname, ',', ' ') AS firstname, u.email, ad.shirt_size
      FROM enrollments en 
      JOIN applicant_details AS ad ON ad.user_id = en.user_id 
      JOIN session_assignments AS sa ON sa.enrollment_id = en.id 
      JOIN camp_occurrences AS co ON sa.camp_occurrence_id = co.id
      LEFT JOIN users AS u ON en.user_id = u.id
      WHERE en.campyear = #{CampConfiguration.active.last.camp_year} AND en.application_status = 'enrolled'
      ORDER BY co.description, ad.shirt_size"
      title = "enrolled_with_sessions_and_tshirt"

      data = data_to_csv(query, title)
      respond_to do |format|
        format.html { send_data data, filename: "MMSS-report-#{title}-#{DateTime.now.strftime('%-d-%-m-%Y')}.csv"}
      end
    end

    def course_assignments
      query = "SELECT co.description AS session, cor.title AS course, 
      REPLACE(ad.lastname, ',', ' ') AS lastname, REPLACE(ad.firstname, ',', ' ') AS firstname, u.email,
      ad.country, ad.state, ad.city,
      (CASE WHEN ad.gender = '' THEN NULL ELSE 
      (SELECT genders.name FROM genders WHERE CAST(ad.gender AS UNSIGNED) = genders.id) END) as gender,
      TIMESTAMPDIFF(YEAR, ad.birthdate, CURDATE()) AS age,
      en.year_in_school, en.personal_statement
      FROM course_assignments ca 
      JOIN enrollments en ON ca.enrollment_id = en.id 
      JOIN applicant_details AS ad ON ad.user_id = en.user_id 
      JOIN courses AS cor ON ca.course_id = cor.id 
      JOIN camp_occurrences AS co ON cor.camp_occurrence_id = co.id
      LEFT JOIN users AS u ON en.user_id = u.id
      WHERE en.campyear = #{CampConfiguration.active.last.camp_year} AND en.application_status = 'enrolled'
      ORDER BY co.description ASC, cor.title, lastname"
      title = "course_assignments"

      data = data_to_csv_list(query, title)

      respond_to do |format|
        format.html { send_data data, filename: "MMSS-report-#{title}-#{DateTime.now.strftime('%-d-%-m-%Y')}.csv"}
      end
    end

    def enrolled_with_covid_verification
      query = "SELECT co.description AS session, REPLACE(ad.lastname, ',', ' ') AS lastname, REPLACE(ad.firstname, ',', ' ') AS firstname, u.email, en.id
      FROM enrollments en 
      JOIN applicant_details AS ad ON ad.user_id = en.user_id 
      JOIN session_assignments AS sa ON sa.enrollment_id = en.id 
      JOIN camp_occurrences AS co ON sa.camp_occurrence_id = co.id
      LEFT JOIN users AS u ON en.user_id = u.id
      WHERE en.campyear = #{CampConfiguration.active.last.camp_year} AND en.application_status = 'enrolled'
      ORDER BY co.description, lastname"
      title = "enrolled_with_covid_verification"

      data = data_to_csv_covid_verification(query, title)
      respond_to do |format|
        format.html { send_data data, filename: "MMSS-report-#{title}-#{DateTime.now.strftime('%-d-%-m-%Y')}.csv"}
      end
    end

    def enrolled_with_addresses_and_more
      query = "Select CONCAT(REPLACE(ad.firstname, ',', ' '), ' ', REPLACE(ad.lastname, ',', ' ')) AS name, REPLACE(ad.lastname, ',', ' ') AS lastname, REPLACE(ad.firstname, ',', ' ') AS firstname, u.email,
              ad.address1, ad.address2, ad.city, ad.state, ad.state_non_us, ad.postalcode, ad.country, ad.birthdate, (CASE WHEN ad.gender = '' THEN NULL ELSE 
              (SELECT genders.name FROM genders WHERE CAST(ad.gender AS UNSIGNED) = genders.id) END) as gender, e.anticipated_graduation_year as graduation_year, e.year_in_school 
              FROM enrollments AS e 
              LEFT JOIN users AS u ON e.user_id = u.id
              JOIN applicant_details AS ad ON ad.user_id = e.user_id
              WHERE e.application_status = 'enrolled' AND e.campyear = #{CampConfiguration.active.last.camp_year} ORDER BY name"
      title = "enrolled_with_addresses_and_more"

      data = data_to_csv(query, title)
      respond_to do |format|
        format.html { send_data data, filename: "MMSS-report-#{title}-#{DateTime.now.strftime('%-d-%-m-%Y')}.csv"}
      end
    end


    def data_to_csv(query, title)
      records_array = ActiveRecord::Base.connection.exec_query(query)
      result = []
      result.push({"total" => records_array.count, "header" => records_array.columns, "rows" => records_array.rows})

      CSV.generate(headers: false) do |csv|
        csv << Array(title.titleize)
        result.each do |res|
          line =[]
          line << "Total number of records: " + res['total'].to_s
          csv << line
          header = res['header'].map! { |e| e.titleize.upcase }
          csv << header
          res['rows'].each do |h|
            csv << h
          end
        end
      end
    end

    def data_to_csv_demographic(query, title)
      records_array = ActiveRecord::Base.connection.exec_query(query)
      result = []
      result.push({"total" => records_array.count, "header" => records_array.columns, "rows" => records_array.rows})

      CSV.generate(headers: false) do |csv|
        csv << Array(title.titleize)
        result.each do |res|
          line =[]
          line << "Total number of records: " + res['total'].to_s
          csv << line
          header = res['header'].map! { |e| e.titleize.upcase }
          csv << header
          res['rows'].each do |row|
            c = row[0]
            if c != 'country'
              row[0] = ISO3166::Country[c].name + " - " + c
            end
            csv << row
          end
        end
      end
    end

    def data_to_csv_with_country(query, title)
      records_array = ActiveRecord::Base.connection.exec_query(query)
      result = []
      result.push({"empty" => "", "total" => records_array.count, "header" => records_array.columns, "rows" => records_array.rows})

      CSV.generate(headers: false) do |csv|
        csv << Array(title.titleize)
        result.each do |res|
          line =[]
          line << res['empty'].to_s + "Total number of records: " + res['total'].to_s
          csv << line
          header = res['header'].map! { |e| e.titleize.upcase }
          header = header.rotate(1)
          csv << header
          res['rows'].each do |row|
            c = row[0]
            if c != 'country'
              row[0] = ISO3166::Country[c].name + " - " + c
            end
            row = row.rotate(1)
            csv << row
          end
        end
      end
    end

    def data_to_csv_list(query, title)
      records_array = ActiveRecord::Base.connection.exec_query(query)
      result = []
      result.push({"total" => records_array.count, "header" => records_array.columns, "rows" => records_array.rows})

      CSV.generate(headers: false) do |csv|
        csv << Array(title.titleize)
        result.each do |res|
          line =[]
          line << "Total number of records: " + res['total'].to_s
          csv << line
          header = res['header'].map! { |e| e.titleize.upcase }
          csv << header
          s2 = ''
          c2 = ''
          res['rows'].each do |row|
            s1 = row[0]
            if s1 == s2
              row[0] = ''
            else
              row[0] = s1
            end
            c1 = row[1]
            if c1 == c2
              row[1] = ''
            else
              row[1] = c1
            end
            country = row[5]
            if country != 'country'
              row[5] = ISO3166::Country[country].name + " - " + country
            end
            csv << row
            s2 = s1
            c2 = c1
          end
        end
      end
    end

    def data_to_csv_covid_verification(query, title)
      records_array = ActiveRecord::Base.connection.exec_query(query)
      result = []
      result.push({"total" => records_array.count, "header" => records_array.columns, "rows" => records_array.rows})

      CSV.generate(headers: false) do |csv|
        csv << Array(title.titleize)
        result.each do |res|
          line =[]
          line << "Total number of records: " + res['total'].to_s
          csv << line
          header = res['header'].map! { |e| e.titleize.upcase }
          header [4] = "VACCINE RECORD"
          header[5] = 'COVID TEST RECORD'
          csv << header
          res['rows'].each do |row|
            en_id = row[4]
            if Enrollment.find(en_id).vaccine_record.attached?
              row[4] = "uploaded"
            else 
              row[4] = "missing"
            end
            if Enrollment.find(en_id).covid_test_record.attached?
              row[5] = "uploaded"
            else 
              row[5] = "missing"
            end
            csv << row
          end
        end
      end
    end

  end
end
