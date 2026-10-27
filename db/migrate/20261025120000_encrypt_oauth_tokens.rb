# frozen_string_literal: true

class EncryptOauthTokens < ActiveRecord::Migration[8.1]
  # Rows written before the tokens were encrypted are plaintext; read them as such once, then rewrite them encrypted.
  def up
    encryption = ActiveRecord::Encryption.config
    was = encryption.support_unencrypted_data
    encryption.support_unencrypted_data = true
    OauthToken.reset_column_information
    OauthToken.find_each(&:encrypt)
  ensure
    encryption.support_unencrypted_data = was
  end

  def down
    OauthToken.find_each(&:decrypt)
  end
end
