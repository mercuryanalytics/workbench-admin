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

ActiveRecord::Schema[8.1].define(version: 2026_10_27_200000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "account_weeks", force: :cascade do |t|
    t.integer "client_id", null: false
    t.date "week", null: false
    t.string "account", null: false
    t.string "segment", null: false
    t.integer "users", null: false
    t.integer "logins", null: false
    t.integer "mercury_ai_reports", null: false
    t.integer "ask_reports", null: false
    t.string "last_project"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id", "week"], name: "index_account_weeks_on_client_id_and_week", unique: true
    t.index ["week"], name: "index_account_weeks_on_week"
  end

  create_table "oauth_tokens", force: :cascade do |t|
    t.string "type", null: false
    t.string "access_token", null: false
    t.datetime "expires_at", null: false
    t.string "refresh_token", null: false
    t.datetime "refresh_expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["type"], name: "index_oauth_tokens_on_type", unique: true
  end
end
