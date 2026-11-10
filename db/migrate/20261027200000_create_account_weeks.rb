# frozen_string_literal: true

class CreateAccountWeeks < ActiveRecord::Migration[8.1]
  def change
    create_table :account_weeks do |t|
      t.integer :client_id, null: false
      t.date :week, null: false
      t.string :account, null: false
      t.string :segment, null: false
      t.integer :users, null: false
      t.integer :logins, null: false
      t.integer :mercury_ai_reports, null: false
      t.integer :ask_reports, null: false
      t.string :last_project
      t.timestamps
    end

    add_index :account_weeks, %i[client_id week], unique: true
    add_index :account_weeks, :week
  end
end
