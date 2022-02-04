ActiveAdmin.register_page "Reports" do
  menu parent: 'Dashboard', priority: 1

  content title: "Reports" do

    columns do
      panel "queries" do
        ul do
          li link_to "report - all complete apps", admin_reports_all_complete_apps_path
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
      query = "SELECT CONCAT(REPLACE(ad.firstname, ',', ' '), ' ', REPLACE(ad.lastname, ',', ' ')) AS name, ad.country,
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
      query = "SELECT CONCAT(REPLACE(ad.firstname, ',', ' '), ' ', REPLACE(ad.lastname, ',', ' ')) AS name, 
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

    def course_assignments_with_students
      query = "SELECT co.description, cor.title, en.user_id, REPLACE(ad.lastname, ',', ' ') AS lastname, REPLACE(ad.firstname, ',', ' ') AS firstname, u.email
      FROM course_assignments ca 
      JOIN enrollments en ON ca.enrollment_id = en.id 
      JOIN applicant_details AS ad ON ad.user_id = en.user_id 
      JOIN courses AS cor ON ca.course_id = cor.id 
      JOIN camp_occurrences AS co ON cor.camp_occurrence_id = co.id
      LEFT JOIN users AS u ON en.user_id = u.id
      ORDER BY co.description, cor.title"
      title = "course_assignments_with_students"

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
          res['header'].shift(1)
          header = res['header'].map! { |e| e.titleize.upcase }
          csv << header
          res['rows'].each do |row|
            row.shift(1)
            c = row[0]
            if c != 'country'
              row[0] = ISO3166::Country[c].name + " - " + c
            end
            csv << row
          end
        end
      end
    end
  end
end
