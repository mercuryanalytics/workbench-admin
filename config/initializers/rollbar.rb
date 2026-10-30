# frozen_string_literal: true

Rollbar.configure do |config|
  config.access_token = Rails.application.credentials.dig(:rollbar, :access_token)
  config.enabled = config.access_token.present? && !Rails.env.local?
  config.environment = Rails.env
end
