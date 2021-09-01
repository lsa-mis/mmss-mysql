ActiveAdmin.register_page "Reports" do
  menu parent: 'Dashboard', priority: 1

  content title: "Reports" do

    columns do
      panel "queries" do
        ul do
          li link_to "report - all complete apps (choose year and status)", admin_reports_all_complete_apps_path
          li link_to "report - registered but not applied", admin_reports_registered_but_not_applied_path
          li link_to "report- enrolled_with_addresses", admin_reports_enrolled_with_addresses_path
          li link_to "report - course_assignments_with_students", admin_reports_course_assignments_with_students_path
          li link_to "report - demographic_report", admin_reports_demographic_report_path
        end
      end
    end
  end # content

  controller do

    def demographic_report
      query = "COPY (SELECT distinct(REPLACE(ad.lastname, ',', ' ') || ' ' || REPLACE(ad.firstname, ',', ' ')) AS name, ad.country,
      CASE gender WHEN '' THEN NULL ELSE 
      (SELECT genders.name AS gender FROM genders WHERE CAST(ad.gender AS INTEGER) = genders.id) END,
      e.year_in_school,
      CASE demographic WHEN '' THEN NULL ELSE 
      (SELECT demographics.name AS demographic FROM demographics WHERE CAST(ad.demographic AS INTEGER) = demographics.id) END,
      e.international
      FROM enrollments AS e 
      LEFT JOIN users AS u ON e.user_id = u.id
      LEFT JOIN applicant_details AS ad ON ad.user_id = e.user_id
      WHERE e.application_status = 'enrolled' AND e.campyear = 2021 ORDER BY country, gender, year_in_school)
      to STDOUT with csv header;"
      make_demographic_csv(query, "demographic_report")
      
    end

    def registered_but_not_applied
      query = "COPY (SELECT u.id, u.email, (ad.firstname || ' ' || ad.lastname) AS name FROM users AS u
      JOIN applicant_details AS ad on u.id = ad.user_id WHERE ad.user_id NOT IN (SELECT e.user_id FROM enrollments AS e))
      to STDOUT with csv header;"
      make_csv(query, "registered_but_not_applied")
    end

    def all_complete_apps
      query = "COPY (SELECT (ad.firstname || ' ' || ad.lastname) AS name, (SELECT genders.name FROM genders WHERE
      CAST(ad.gender AS INTEGER) = genders.id) as gender, ad.us_citizen as us_citizen,
      (SELECT demographics.name FROM demographics WHERE CAST(ad.demographic AS INTEGER) = demographics.id) as demographic,
      ad.birthdate as birthdate, ad.diet_restrictions as diet_restrictions,
      ad.shirt_size as shirt_size, (ad.address1 || ' ' || ad.address2 || ' ' || ad.city || ' ' ||
      ad.state || ' ' || ad.state_non_us || ' ' || ad.postalcode || ' ' || ad.country) AS address,
      ad.phone as phone, ad.parentname as parentname,
      (ad.parentaddress1 || ' ' || ad.parentaddress2 || ' ' || ad.parentcity || ' ' || ad.parentstate || ' ' ||
      ad.parentstate_non_us || ' ' || ad.parentzip || ' ' || ad.parentcountry) as parent_address,
      ad.parentphone as parentphone, ad.parentworkphone as parentworkphone, ad.parentemail as parentemail,
      e.user_id as user_id, e.international as international, e.high_school_name as high_school_name,
      (e.high_school_address1 || ' ' || e.high_school_address2 || ' ' ||
      e.high_school_city || ' ' || e.high_school_state || ' ' ||
      e.high_school_non_us || ' ' || e.high_school_postalcode || ' ' ||
      e.high_school_country) AS high_school_address, e.year_in_school as year_in_school,
      e.anticipated_graduation_year as anticipated_graduation_year, e.room_mate_request as room_mate_request,
      e.personal_statement as personal_statement, e.notes as notes,
      e.application_status as application_status, e.offer_status as offer_status,
      r.email AS recommender_email, (r.lastname || ' ' || r.firstname) AS recommender_name, r.organization AS recommender_organization,
      (fa.amount_cents / 100) AS fin_aid_ammount, fa.source AS fin_aid_source, fa.note AS fin_aid_note, fa.status AS fin_aid_status
      FROM enrollments AS e LEFT JOIN applicant_details AS ad ON ad.user_id = e.user_id
      LEFT JOIN recommendations AS r ON r.enrollment_id = e.id
      LEFT JOIN financial_aids AS fa ON fa.enrollment_id = e.id) to STDOUT with csv header;"
      make_csv(query, "all_complete_apps")
    end

    def enrolled_with_addresses
      query = "COPY (Select distinct(ad.lastname || ', ' || ad.firstname) AS name, ad.lastname, ad.firstname, u.email,
              ad.address1, ad.address2, ad.city, ad.state, ad.state_non_us, ad.postalcode, ad.country 
              FROM enrollments AS e 
              LEFT JOIN users AS u ON e.user_id = u.id
              JOIN applicant_details AS ad ON ad.user_id = e.user_id
              WHERE e.application_status = 'enrolled' AND e.campyear = 2021 ORDER BY name)
              to STDOUT with csv header;"
      make_csv(query, "enrolled_with_addresses")
    end

    def course_assignments_with_students
      query = "COPY (SELECT co.description, cor.title, en.user_id, ad.lastname, ad.firstname, u.email
      FROM course_assignments ca 
      JOIN enrollments en ON ca.enrollment_id = en.id 
      JOIN applicant_details AS ad ON ad.user_id = en.user_id 
      JOIN courses AS cor ON ca.course_id = cor.id 
      JOIN camp_occurrences AS co ON cor.camp_occurrence_id = co.id
      LEFT JOIN users AS u ON en.user_id = u.id
      ORDER BY co.description, cor.title)
      to STDOUT with csv header;"
      make_csv(query, "course_assignments_with_students")
    end

    def make_csv(query, title)
      csv = []
      connection_pool = ActiveRecord::Base.connection_pool
      connection = connection_pool.checkout
      raw_connection  = connection.raw_connection
      raw_connection.copy_data(query) do
        while row = raw_connection.get_copy_data
          csv.push(row)
        end
      end
      connection_pool.checkin connection
      sql_data_as_string = csv.join("")

      respond_to do |format|
        format.html { send_data sql_data_as_string.force_encoding("UTF-8"), filename: "#{title}-#{Date.today}.csv" }
      end
    end

    def make_demographic_csv(query, title)
      csv = []
      connection_pool = ActiveRecord::Base.connection_pool
      connection = connection_pool.checkout
      raw_connection  = connection.raw_connection
      raw_connection.copy_data(query) do
        while row = raw_connection.get_copy_data
          row = row.split(',', 2).last
          c = row.split(",")[0]
          if c != 'country'
            row = ISO3166::Country[c].name + " - " +  row
          end
          csv.push(row)
        end
      end
      connection_pool.checkin connection
      sql_data_as_string = csv.join("")

      respond_to do |format|
        format.html { send_data sql_data_as_string.force_encoding("UTF-8"), filename: "#{title}-#{Date.today}.csv" }
      end
    end

  end
end