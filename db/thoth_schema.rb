# frozen_string_literal: true

# Only the thoth columns workbench-admin reads; the live database is owned by thoth.
ActiveRecord::Schema[8.1].define(version: 1) do
  create_table "completions", force: :cascade do |t|
    t.string "project", null: false
    t.string "user"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.boolean "deliverable", default: false, null: false
    t.string "status", default: "pending", null: false
  end
end
