# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2024_12_11_195358) do

  create_table "active_admin_comments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id"
  end

  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "activities", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "camp_occurrence_id"
    t.string "description"
    t.integer "cost_cents"
    t.date "date_occurs"
    t.boolean "active", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["camp_occurrence_id"], name: "index_activities_on_camp_occurrence_id"
  end

  create_table "admins", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true
  end

  create_table "applicant_details", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "firstname", null: false
    t.string "middlename"
    t.string "lastname", null: false
    t.string "gender"
    t.boolean "us_citizen", default: false, null: false
    t.date "birthdate", null: false
    t.text "diet_restrictions"
    t.string "shirt_size"
    t.string "address1", null: false
    t.string "address2"
    t.string "city", null: false
    t.string "state", null: false
    t.string "state_non_us"
    t.string "postalcode", null: false
    t.string "country", null: false
    t.string "phone", null: false
    t.string "parentname", null: false
    t.string "parentaddress1"
    t.string "parentaddress2"
    t.string "parentcity"
    t.string "parentstate"
    t.string "parentstate_non_us"
    t.string "parentzip"
    t.string "parentcountry"
    t.string "parentphone", null: false
    t.string "parentworkphone"
    t.string "parentemail"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "demographic_other"
    t.bigint "demographic_id"
    t.index ["demographic_id"], name: "index_applicant_details_on_demographic_id"
    t.index ["user_id"], name: "index_applicant_details_on_user_id"
  end

  create_table "camp_configurations", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "camp_year", null: false
    t.date "application_open", null: false
    t.date "application_close", null: false
    t.date "priority", null: false
    t.date "application_materials_due", null: false
    t.date "camper_acceptance_due", null: false
    t.boolean "active", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "offer_letter"
    t.string "student_packet_url"
    t.integer "application_fee_cents"
    t.text "reject_letter"
    t.text "waitlist_letter"
    t.boolean "application_fee_required", default: true, null: false
    t.index ["camp_year"], name: "index_camp_configurations_on_camp_year", unique: true
  end

  create_table "camp_occurrences", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "camp_configuration_id", null: false
    t.string "description", null: false
    t.date "begin_date", null: false
    t.date "end_date", null: false
    t.boolean "active", default: false, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "cost_cents"
    t.index ["camp_configuration_id"], name: "index_camp_occurrences_on_camp_configuration_id"
  end

  create_table "campnotes", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "note"
    t.datetime "opendate"
    t.datetime "closedate"
    t.string "notetype"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "course_assignments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "enrollment_id", null: false
    t.bigint "course_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "wait_list", default: false
    t.index ["course_id"], name: "index_course_assignments_on_course_id"
    t.index ["enrollment_id"], name: "index_course_assignments_on_enrollment_id"
  end

  create_table "course_preferences", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "enrollment_id", null: false
    t.bigint "course_id", null: false
    t.integer "ranking"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["course_id"], name: "index_course_preferences_on_course_id"
    t.index ["enrollment_id"], name: "index_course_preferences_on_enrollment_id"
  end

  create_table "courses", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "camp_occurrence_id", null: false
    t.string "title"
    t.integer "available_spaces"
    t.string "status"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "faculty_uniqname"
    t.string "faculty_name"
    t.index ["camp_occurrence_id"], name: "index_courses_on_camp_occurrence_id"
  end

  create_table "demographics", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "description", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "protected", default: false
  end

  create_table "enrollment_activities", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "enrollment_id", null: false
    t.bigint "activity_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["activity_id"], name: "index_enrollment_activities_on_activity_id"
    t.index ["enrollment_id"], name: "index_enrollment_activities_on_enrollment_id"
  end

  create_table "enrollments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.boolean "international", default: false, null: false
    t.string "high_school_name", null: false
    t.string "high_school_address1", null: false
    t.string "high_school_address2"
    t.string "high_school_city", null: false
    t.string "high_school_state"
    t.string "high_school_non_us"
    t.string "high_school_postalcode"
    t.string "high_school_country", null: false
    t.string "year_in_school", null: false
    t.string "anticipated_graduation_year", null: false
    t.string "room_mate_request"
    t.text "personal_statement", null: false
    t.text "notes"
    t.string "application_status"
    t.string "offer_status"
    t.string "partner_program"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "campyear"
    t.date "application_deadline"
    t.date "application_status_updated_on"
    t.string "uniqname"
    t.boolean "camp_doc_form_completed", default: false
    t.index ["user_id"], name: "index_enrollments_on_user_id"
  end

  create_table "faculties", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["email"], name: "index_faculties_on_email", unique: true
    t.index ["reset_password_token"], name: "index_faculties_on_reset_password_token", unique: true
  end

  create_table "feedbacks", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "genre"
    t.string "message"
    t.bigint "user_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_feedbacks_on_user_id"
  end

  create_table "financial_aids", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "enrollment_id", null: false
    t.integer "amount_cents", default: 0
    t.string "source"
    t.text "note"
    t.string "status", default: "pending"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.date "payments_deadline"
    t.index ["enrollment_id"], name: "index_financial_aids_on_enrollment_id"
  end

  create_table "genders", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "payments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "transaction_type"
    t.string "transaction_status"
    t.string "transaction_id"
    t.string "total_amount"
    t.string "transaction_date"
    t.string "account_type"
    t.string "result_code"
    t.string "result_message"
    t.string "user_account"
    t.string "payer_identity"
    t.string "timestamp"
    t.string "transaction_hash"
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "camp_year"
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "recommendations", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "enrollment_id", null: false
    t.string "email", null: false
    t.string "lastname", null: false
    t.string "firstname", null: false
    t.string "organization"
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "state"
    t.string "state_non_us"
    t.string "postalcode"
    t.string "country"
    t.string "phone_number"
    t.string "best_contact_time"
    t.string "submitted_recommendation"
    t.datetime "date_submitted"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["enrollment_id"], name: "index_recommendations_on_enrollment_id"
  end

  create_table "recuploads", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.text "letter"
    t.string "authorname", null: false
    t.string "studentname", null: false
    t.bigint "recommendation_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["recommendation_id"], name: "index_recuploads_on_recommendation_id"
  end

  create_table "rejections", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "enrollment_id", null: false
    t.text "reason"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["enrollment_id"], name: "index_rejections_on_enrollment_id"
  end

  create_table "session_activities", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "enrollment_id", null: false
    t.bigint "camp_occurrence_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["camp_occurrence_id"], name: "index_session_activities_on_camp_occurrence_id"
    t.index ["enrollment_id"], name: "index_session_activities_on_enrollment_id"
  end

  create_table "session_assignments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "enrollment_id", null: false
    t.bigint "camp_occurrence_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "offer_status"
    t.index ["camp_occurrence_id"], name: "index_session_assignments_on_camp_occurrence_id"
    t.index ["enrollment_id"], name: "index_session_assignments_on_enrollment_id"
  end

  create_table "travels", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "enrollment_id", null: false
    t.string "arrival_transport"
    t.string "arrival_carrier"
    t.string "arrival_route_num"
    t.text "note"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.date "arrival_date"
    t.time "arrival_time"
    t.string "depart_transport"
    t.string "depart_route_num"
    t.date "depart_date"
    t.time "depart_time"
    t.string "depart_carrier"
    t.string "arrival_session"
    t.string "depart_session"
    t.index ["enrollment_id"], name: "index_travels_on_enrollment_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activities", "camp_occurrences"
  add_foreign_key "applicant_details", "demographics"
  add_foreign_key "applicant_details", "users"
  add_foreign_key "camp_occurrences", "camp_configurations"
  add_foreign_key "course_assignments", "courses"
  add_foreign_key "course_assignments", "enrollments"
  add_foreign_key "course_preferences", "courses"
  add_foreign_key "course_preferences", "enrollments"
  add_foreign_key "courses", "camp_occurrences"
  add_foreign_key "enrollment_activities", "activities"
  add_foreign_key "enrollment_activities", "enrollments"
  add_foreign_key "enrollments", "users"
  add_foreign_key "feedbacks", "users"
  add_foreign_key "financial_aids", "enrollments"
  add_foreign_key "payments", "users"
  add_foreign_key "recommendations", "enrollments"
  add_foreign_key "recuploads", "recommendations"
  add_foreign_key "rejections", "enrollments"
  add_foreign_key "session_activities", "camp_occurrences"
  add_foreign_key "session_activities", "enrollments"
  add_foreign_key "session_assignments", "camp_occurrences"
  add_foreign_key "session_assignments", "enrollments"
  add_foreign_key "travels", "enrollments"
end
