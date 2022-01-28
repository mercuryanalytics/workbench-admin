# frozen_string_literal: true

Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.keep_original_rails_log = true

  config.lograge.custom_options = lambda do |_event|
    { time: Time.zone.now.utc.iso8601(3) }
  end

  config.lograge.formatter = Lograge::Formatters::Json.new
  config.lograge.logger = ActiveSupport::Logger.new Rails.root.join("log/#{Rails.env}.json")
end
