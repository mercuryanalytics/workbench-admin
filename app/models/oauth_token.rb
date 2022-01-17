# frozen_string_literal: true

class OauthToken < ApplicationRecord
  include QuickbooksOauth

  validates :type, presence: true, uniqueness: true
  validates :access_token, presence: true
  validates :expires_at, presence: true
  validates :refresh_token, presence: true
end
