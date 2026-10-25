# frozen_string_literal: true

class OauthToken < ApplicationRecord
  include QuickbooksOauth

  # Intuit requires OAuth tokens to be encrypted at rest; the keys live in the credentials file.
  encrypts :access_token, :refresh_token

  validates :type, presence: true, uniqueness: true
  validates :access_token, presence: true
  validates :expires_at, presence: true
  validates :refresh_token, presence: true
end
