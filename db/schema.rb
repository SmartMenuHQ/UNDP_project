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

ActiveRecord::Schema[8.0].define(version: 2025_08_10_160627) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "assessment_marking_schemes", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.decimal "total_possible_score", precision: 10, scale: 2, default: "0.0"
    t.boolean "is_active", default: true
    t.jsonb "settings", default: {}
    t.bigint "assessment_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assessment_id"], name: "index_assessment_marking_schemes_on_assessment_id"
    t.index ["is_active"], name: "index_assessment_marking_schemes_on_is_active"
    t.index ["name"], name: "index_assessment_marking_schemes_on_name"
  end

  create_table "assessment_question_marking_rules", force: :cascade do |t|
    t.string "rule_type", null: false
    t.decimal "points", precision: 10, scale: 2, default: "0.0"
    t.jsonb "criteria", default: {}
    t.boolean "is_active", default: true
    t.integer "order", default: 0
    t.bigint "assessment_question_id", null: false
    t.bigint "assessment_marking_scheme_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assessment_marking_scheme_id"], name: "idx_on_assessment_marking_scheme_id_ac1d6c24c2"
    t.index ["assessment_question_id"], name: "idx_on_assessment_question_id_229c1b774d"
    t.index ["is_active"], name: "index_assessment_question_marking_rules_on_is_active"
    t.index ["order"], name: "index_assessment_question_marking_rules_on_order"
    t.index ["rule_type"], name: "index_assessment_question_marking_rules_on_rule_type"
  end

  create_table "assessment_question_options", force: :cascade do |t|
    t.bigint "assessment_id", null: false
    t.bigint "assessment_question_id", null: false
    t.jsonb "text", default: {}
    t.integer "order"
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "default_locale"
    t.decimal "points", precision: 10, scale: 2, default: "0.0"
    t.boolean "is_correct_answer", default: false
    t.index ["assessment_id"], name: "index_assessment_question_options_on_assessment_id"
    t.index ["assessment_question_id"], name: "index_assessment_question_options_on_assessment_question_id"
    t.index ["is_correct_answer"], name: "index_assessment_question_options_on_is_correct_answer"
    t.index ["points"], name: "index_assessment_question_options_on_points"
  end

  create_table "assessment_question_responses", force: :cascade do |t|
    t.bigint "assessment_question_id", null: false
    t.bigint "assessment_id", null: false
    t.jsonb "value", default: {}
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "assessment_response_session_id"
    t.index ["assessment_id"], name: "index_assessment_question_responses_on_assessment_id"
    t.index ["assessment_question_id"], name: "index_assessment_question_responses_on_assessment_question_id"
    t.index ["assessment_response_session_id"], name: "idx_on_assessment_response_session_id_4618f6d7db"
  end

  create_table "assessment_questions", force: :cascade do |t|
    t.string "type"
    t.boolean "is_required", default: false
    t.integer "order"
    t.string "default_locale"
    t.jsonb "text", default: {}
    t.jsonb "options_json"
    t.jsonb "meta_data", default: {}
    t.bigint "assessment_section_id"
    t.bigint "assessment_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: true
    t.string "sub_type"
    t.jsonb "visibility_conditions", default: {}
    t.boolean "is_conditional", default: false
    t.jsonb "restricted_countries", default: []
    t.boolean "has_country_restrictions", default: false, null: false
    t.index ["assessment_id"], name: "index_assessment_questions_on_assessment_id"
    t.index ["assessment_section_id"], name: "index_assessment_questions_on_assessment_section_id"
    t.index ["has_country_restrictions"], name: "index_assessment_questions_on_has_country_restrictions"
    t.index ["is_conditional"], name: "index_assessment_questions_on_is_conditional"
    t.index ["restricted_countries"], name: "index_assessment_questions_on_restricted_countries", using: :gin
    t.index ["visibility_conditions"], name: "index_assessment_questions_on_visibility_conditions", using: :gin
  end

  create_table "assessment_response_scores", force: :cascade do |t|
    t.decimal "score_earned", precision: 10, scale: 2, default: "0.0"
    t.decimal "max_possible_score", precision: 10, scale: 2, default: "0.0"
    t.jsonb "scoring_details", default: {}
    t.text "feedback"
    t.bigint "assessment_question_response_id", null: false
    t.bigint "assessment_marking_scheme_id", null: false
    t.bigint "assessment_question_marking_rule_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assessment_marking_scheme_id"], name: "idx_on_assessment_marking_scheme_id_2772f2d268"
    t.index ["assessment_question_marking_rule_id"], name: "idx_on_assessment_question_marking_rule_id_e720f6ab10"
    t.index ["assessment_question_response_id"], name: "idx_on_assessment_question_response_id_bd971c83ee"
    t.index ["max_possible_score"], name: "index_assessment_response_scores_on_max_possible_score"
    t.index ["score_earned"], name: "index_assessment_response_scores_on_score_earned"
  end

  create_table "assessment_response_sessions", force: :cascade do |t|
    t.bigint "assessment_id", null: false
    t.string "respondent_name", null: false
    t.string "state", default: "draft", null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "submitted_at"
    t.datetime "marked_at"
    t.decimal "total_score", precision: 10, scale: 2, default: "0.0"
    t.decimal "max_possible_score", precision: 10, scale: 2, default: "0.0"
    t.string "grade"
    t.text "feedback"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["assessment_id", "state"], name: "index_assessment_response_sessions_on_assessment_id_and_state"
    t.index ["assessment_id"], name: "index_assessment_response_sessions_on_assessment_id"
    t.index ["completed_at"], name: "index_assessment_response_sessions_on_completed_at"
    t.index ["marked_at"], name: "index_assessment_response_sessions_on_marked_at"
    t.index ["started_at"], name: "index_assessment_response_sessions_on_started_at"
    t.index ["state"], name: "index_assessment_response_sessions_on_state"
    t.index ["submitted_at"], name: "index_assessment_response_sessions_on_submitted_at"
    t.index ["total_score"], name: "index_assessment_response_sessions_on_total_score"
    t.index ["user_id"], name: "index_assessment_response_sessions_on_user_id"
  end

  create_table "assessment_sections", force: :cascade do |t|
    t.string "name"
    t.integer "order"
    t.jsonb "metadata"
    t.bigint "assessment_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "visibility_conditions", default: {}
    t.boolean "is_conditional", default: false
    t.jsonb "restricted_countries", default: []
    t.boolean "has_country_restrictions", default: false, null: false
    t.index ["assessment_id"], name: "index_assessment_sections_on_assessment_id"
    t.index ["has_country_restrictions"], name: "index_assessment_sections_on_has_country_restrictions"
    t.index ["is_conditional"], name: "index_assessment_sections_on_is_conditional"
    t.index ["restricted_countries"], name: "index_assessment_sections_on_restricted_countries", using: :gin
    t.index ["visibility_conditions"], name: "index_assessment_sections_on_visibility_conditions", using: :gin
  end

  create_table "assessments", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "restricted_countries", default: []
    t.boolean "has_country_restrictions", default: false, null: false
    t.index ["has_country_restrictions"], name: "index_assessments_on_has_country_restrictions"
    t.index ["restricted_countries"], name: "index_assessments_on_restricted_countries", using: :gin
  end

  create_table "countries", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", limit: 3, null: false
    t.boolean "active", default: true, null: false
    t.string "region"
    t.integer "sort_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active", "sort_order"], name: "index_countries_on_active_and_sort_order"
    t.index ["active"], name: "index_countries_on_active"
    t.index ["code"], name: "index_countries_on_code", unique: true
    t.index ["region"], name: "index_countries_on_region"
    t.index ["sort_order"], name: "index_countries_on_sort_order"
  end

  create_table "mobility_string_translations", force: :cascade do |t|
    t.string "locale", null: false
    t.string "key", null: false
    t.string "value"
    t.string "translatable_type"
    t.bigint "translatable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["translatable_id", "translatable_type", "key"], name: "index_mobility_string_translations_on_translatable_attribute"
    t.index ["translatable_id", "translatable_type", "locale", "key"], name: "index_mobility_string_translations_on_keys", unique: true
    t.index ["translatable_type", "key", "value", "locale"], name: "index_mobility_string_translations_on_query_keys"
  end

  create_table "mobility_text_translations", force: :cascade do |t|
    t.string "locale", null: false
    t.string "key", null: false
    t.text "value"
    t.string "translatable_type"
    t.bigint "translatable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["translatable_id", "translatable_type", "key"], name: "index_mobility_text_translations_on_translatable_attribute"
    t.index ["translatable_id", "translatable_type", "locale", "key"], name: "index_mobility_text_translations_on_keys", unique: true
  end

  create_table "selected_options", force: :cascade do |t|
    t.bigint "assessment_question_response_id", null: false
    t.bigint "assessment_question_option_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assessment_question_option_id"], name: "index_selected_options_on_assessment_question_option_id"
    t.index ["assessment_question_response_id", "assessment_question_option_id"], name: "index_selected_options_unique", unique: true
    t.index ["assessment_question_response_id"], name: "index_selected_options_on_assessment_question_response_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.string "token", null: false
    t.datetime "expires_at", null: false
    t.index ["expires_at"], name: "index_sessions_on_expires_at"
    t.index ["token"], name: "index_sessions_on_token", unique: true
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.boolean "admin", default: false, null: false
    t.string "first_name"
    t.string "last_name"
    t.bigint "country_id"
    t.string "default_language", default: "en"
    t.boolean "profile_completed", default: false, null: false
    t.bigint "invited_by_id"
    t.datetime "invited_at"
    t.datetime "invitation_accepted_at"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["admin"], name: "index_users_on_admin"
    t.index ["country_id"], name: "index_users_on_country_id"
    t.index ["default_language"], name: "index_users_on_default_language"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["profile_completed"], name: "index_users_on_profile_completed"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "assessment_marking_schemes", "assessments"
  add_foreign_key "assessment_question_marking_rules", "assessment_marking_schemes"
  add_foreign_key "assessment_question_marking_rules", "assessment_questions"
  add_foreign_key "assessment_question_options", "assessment_questions"
  add_foreign_key "assessment_question_options", "assessments"
  add_foreign_key "assessment_question_responses", "assessment_questions"
  add_foreign_key "assessment_question_responses", "assessment_response_sessions"
  add_foreign_key "assessment_question_responses", "assessments"
  add_foreign_key "assessment_response_scores", "assessment_marking_schemes"
  add_foreign_key "assessment_response_scores", "assessment_question_marking_rules"
  add_foreign_key "assessment_response_scores", "assessment_question_responses"
  add_foreign_key "assessment_response_sessions", "assessments"
  add_foreign_key "assessment_response_sessions", "users"
  add_foreign_key "assessment_sections", "assessments"
  add_foreign_key "selected_options", "assessment_question_options"
  add_foreign_key "selected_options", "assessment_question_responses"
  add_foreign_key "sessions", "users"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "users", "countries"
  add_foreign_key "users", "users", column: "invited_by_id"
end
