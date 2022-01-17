# frozen_string_literal: true

class CreateOauthTokens < ActiveRecord::Migration[7.0]
  def change
    create_table :oauth_tokens do |t|
      t.string :type, null: false
      t.string :access_token, null: false
      t.datetime :expires_at, null: false
      t.string :refresh_token, null: false
      t.datetime :refresh_expires_at

      t.timestamps
    end

    add_index :oauth_tokens, :type, unique: true
  end
end
