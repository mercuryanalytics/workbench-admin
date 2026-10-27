# frozen_string_literal: true

# Only the petasos columns workbench-admin reads; the live database is owned by petasos.
ActiveRecord::Schema[8.1].define(version: 1) do
  create_table "clients", force: :cascade do |t|
    t.string "name"
  end

  create_table "memberships", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "user_id", null: false
  end

  create_table "projects", force: :cascade do |t|
    t.string "name"
    t.string "project_number"
    t.integer "domain_id"
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.datetime "last_login", precision: nil
  end
end
