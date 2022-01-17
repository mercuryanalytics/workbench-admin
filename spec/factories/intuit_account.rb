# frozen_string_literal: true

FactoryBot.define do
  factory :intuit_account do
    access_token { "access-token" }
    expires_at { 1.hour.from_now }
    refresh_token { "refresh-token" }
  end
end
