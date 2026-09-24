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

ActiveRecord::Schema[8.1].define(version: 2026_09_24_135333) do
  create_table "active_admin_comments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "author_id"
    t.string "author_type"
    t.text "body"
    t.datetime "created_at", null: false
    t.string "namespace"
    t.bigint "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id"
  end

  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activities", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.boolean "active", default: false
    t.bigint "camp_occurrence_id"
    t.integer "cost_cents"
    t.datetime "created_at", null: false
    t.date "date_occurs"
    t.string "description"
    t.datetime "updated_at", null: false
    t.index ["camp_occurrence_id"], name: "index_activities_on_camp_occurrence_id"
  end

  create_table "admins", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "locked_at"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true
  end

  create_table "applicant_details", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "address1", null: false
    t.string "address2"
    t.date "birthdate", null: false
    t.string "city", null: false
    t.string "country", null: false
    t.datetime "created_at", null: false
    t.bigint "demographic_id"
    t.string "demographic_other"
    t.text "diet_restrictions"
    t.string "firstname", null: false
    t.string "gender"
    t.string "lastname", null: false
    t.string "middlename"
    t.string "parentaddress1"
    t.string "parentaddress2"
    t.string "parentcity"
    t.string "parentcountry"
    t.string "parentemail"
    t.string "parentname", null: false
    t.string "parentphone", null: false
    t.string "parentstate"
    t.string "parentstate_non_us"
    t.string "parentworkphone"
    t.string "parentzip"
    t.string "phone", null: false
    t.string "postalcode", null: false
    t.string "shirt_size"
    t.string "state", null: false
    t.string "state_non_us"
    t.datetime "updated_at", null: false
    t.boolean "us_citizen", default: false, null: false
    t.bigint "user_id", null: false
    t.index ["demographic_id"], name: "index_applicant_details_on_demographic_id"
    t.index ["user_id"], name: "index_applicant_details_on_user_id"
  end

  create_table "camp_configurations", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.boolean "active", default: false, null: false
    t.date "application_close", null: false
    t.integer "application_fee_cents"
    t.boolean "application_fee_required", default: true, null: false
    t.date "application_materials_due", null: false
    t.date "application_open", null: false
    t.integer "camp_year", null: false
    t.date "camper_acceptance_due", null: false
    t.datetime "created_at", null: false
    t.text "offer_letter"
    t.date "priority", null: false
    t.text "reject_letter"
    t.string "student_packet_url"
    t.datetime "updated_at", null: false
    t.text "waitlist_letter"
    t.index ["camp_year"], name: "index_camp_configurations_on_camp_year", unique: true
  end

  create_table "camp_occurrences", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.boolean "active", default: false, null: false
    t.date "begin_date", null: false
    t.bigint "camp_configuration_id", null: false
    t.integer "cost_cents"
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.date "end_date", null: false
    t.datetime "updated_at", null: false
    t.index ["camp_configuration_id"], name: "index_camp_occurrences_on_camp_configuration_id"
  end

  create_table "campnotes", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "closedate"
    t.datetime "created_at", null: false
    t.string "note"
    t.string "notetype"
    t.datetime "opendate"
    t.datetime "updated_at", null: false
  end

  create_table "course_assignments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "course_id", null: false
    t.datetime "created_at", null: false
    t.bigint "enrollment_id", null: false
    t.datetime "updated_at", null: false
    t.boolean "wait_list", default: false
    t.index ["course_id"], name: "index_course_assignments_on_course_id"
    t.index ["enrollment_id"], name: "index_course_assignments_on_enrollment_id"
  end

  create_table "course_preferences", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "course_id", null: false
    t.datetime "created_at", null: false
    t.bigint "enrollment_id", null: false
    t.integer "ranking"
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_course_preferences_on_course_id"
    t.index ["enrollment_id"], name: "index_course_preferences_on_enrollment_id"
  end

  create_table "courses", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "available_spaces"
    t.bigint "camp_occurrence_id", null: false
    t.datetime "created_at", null: false
    t.string "faculty_name"
    t.string "faculty_uniqname"
    t.string "status"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["camp_occurrence_id"], name: "index_courses_on_camp_occurrence_id"
  end

  create_table "demographics", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.string "name", null: false
    t.boolean "protected", default: false
    t.datetime "updated_at", null: false
  end

  create_table "enrollment_activities", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "activity_id", null: false
    t.datetime "created_at", null: false
    t.bigint "enrollment_id", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_id"], name: "index_enrollment_activities_on_activity_id"
    t.index ["enrollment_id"], name: "index_enrollment_activities_on_enrollment_id"
  end

  create_table "enrollments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "anticipated_graduation_year", null: false
    t.date "application_deadline"
    t.boolean "application_fee_required", default: true, null: false
    t.string "application_status"
    t.date "application_status_updated_on"
    t.boolean "camp_doc_form_completed", default: false
    t.integer "campyear"
    t.datetime "created_at", null: false
    t.string "high_school_address1", null: false
    t.string "high_school_address2"
    t.string "high_school_city", null: false
    t.string "high_school_country", null: false
    t.string "high_school_name", null: false
    t.string "high_school_non_us"
    t.string "high_school_postalcode"
    t.string "high_school_state"
    t.boolean "international", default: false, null: false
    t.text "notes"
    t.string "offer_status"
    t.string "partner_program"
    t.text "personal_statement", null: false
    t.string "room_mate_request"
    t.string "uniqname"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "year_in_school", null: false
    t.index ["user_id"], name: "index_enrollments_on_user_id"
  end

  create_table "faculties", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_faculties_on_email", unique: true
    t.index ["reset_password_token"], name: "index_faculties_on_reset_password_token", unique: true
  end

  create_table "feedbacks", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "genre"
    t.string "message"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_feedbacks_on_user_id"
  end

  create_table "financial_aids", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "adjusted_gross_income"
    t.integer "amount_cents", default: 0
    t.datetime "created_at", null: false
    t.bigint "enrollment_id", null: false
    t.text "note"
    t.date "payments_deadline"
    t.string "source"
    t.string "status", default: "pending"
    t.datetime "updated_at", null: false
    t.index ["enrollment_id"], name: "index_financial_aids_on_enrollment_id"
  end

  create_table "genders", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "nelnet_callback_logs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "order_number", comment: "orderNumber from callback (user_account)"
    t.text "raw_params", comment: "Full request params as JSON"
    t.string "transaction_id", comment: "Nelnet transactionId from callback"
    t.string "transaction_status"
    t.string "transaction_total_amount"
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_nelnet_callback_logs_on_created_at"
    t.index ["order_number"], name: "index_nelnet_callback_logs_on_order_number"
    t.index ["transaction_id"], name: "index_nelnet_callback_logs_on_transaction_id"
  end

  create_table "payment_requests", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "amount_cents", null: false, comment: "Amount sent in request (cents)"
    t.integer "camp_year"
    t.datetime "created_at", null: false
    t.string "order_number", null: false, comment: "Sent to Nelnet as orderNumber (user_account)"
    t.bigint "payment_id", comment: "Set when receipt received"
    t.bigint "request_timestamp", null: false, comment: "Epoch timestamp sent in URL to Nelnet"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["payment_id"], name: "index_payment_requests_on_payment_id"
    t.index ["user_id", "order_number"], name: "index_payment_requests_on_user_id_and_order_number"
    t.index ["user_id"], name: "index_payment_requests_on_user_id"
  end

  create_table "payments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "account_type"
    t.integer "camp_year"
    t.datetime "created_at", null: false
    t.string "payer_identity"
    t.string "result_code"
    t.string "result_message"
    t.string "timestamp"
    t.string "total_amount"
    t.string "transaction_date"
    t.string "transaction_hash"
    t.string "transaction_id"
    t.string "transaction_status"
    t.string "transaction_type"
    t.datetime "updated_at", null: false
    t.string "user_account"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "recommendations", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "address1"
    t.string "address2"
    t.string "best_contact_time"
    t.string "city"
    t.string "country"
    t.datetime "created_at", null: false
    t.datetime "date_submitted"
    t.string "email", null: false
    t.bigint "enrollment_id", null: false
    t.string "firstname", null: false
    t.string "lastname", null: false
    t.string "organization"
    t.string "phone_number"
    t.string "postalcode"
    t.string "state"
    t.string "state_non_us"
    t.string "submitted_recommendation"
    t.datetime "updated_at", null: false
    t.index ["enrollment_id"], name: "index_recommendations_on_enrollment_id"
  end

  create_table "recuploads", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "authorname", null: false
    t.datetime "created_at", null: false
    t.text "letter"
    t.bigint "recommendation_id", null: false
    t.string "studentname", null: false
    t.datetime "updated_at", null: false
    t.index ["recommendation_id"], name: "index_recuploads_on_recommendation_id"
  end

  create_table "rejections", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "enrollment_id", null: false
    t.text "reason"
    t.datetime "updated_at", null: false
    t.index ["enrollment_id"], name: "index_rejections_on_enrollment_id"
  end

  create_table "session_activities", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "camp_occurrence_id", null: false
    t.datetime "created_at", null: false
    t.bigint "enrollment_id", null: false
    t.datetime "updated_at", null: false
    t.index ["camp_occurrence_id"], name: "index_session_activities_on_camp_occurrence_id"
    t.index ["enrollment_id"], name: "index_session_activities_on_enrollment_id"
  end

  create_table "session_assignments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "camp_occurrence_id", null: false
    t.datetime "created_at", null: false
    t.bigint "enrollment_id", null: false
    t.string "offer_status"
    t.datetime "updated_at", null: false
    t.index ["camp_occurrence_id"], name: "index_session_assignments_on_camp_occurrence_id"
    t.index ["enrollment_id"], name: "index_session_assignments_on_enrollment_id"
  end

  create_table "travels", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "arrival_carrier"
    t.date "arrival_date"
    t.string "arrival_route_num"
    t.string "arrival_session"
    t.time "arrival_time"
    t.string "arrival_transport"
    t.datetime "created_at", null: false
    t.string "depart_carrier"
    t.date "depart_date"
    t.string "depart_route_num"
    t.string "depart_session"
    t.time "depart_time"
    t.string "depart_transport"
    t.bigint "enrollment_id", null: false
    t.text "note"
    t.datetime "updated_at", null: false
    t.index ["enrollment_id"], name: "index_travels_on_enrollment_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
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
  add_foreign_key "payment_requests", "payments"
  add_foreign_key "payment_requests", "users"
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
