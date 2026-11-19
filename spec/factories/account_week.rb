# frozen_string_literal: true

FactoryBot.define do
  factory :account_week do
    sequence(:client_id)
    week { Date.new(2026, 10, 19) }
    account { "Acme" }
    segment { "dormant" }
    users { 1 }
    logins { 0 }
    mercury_ai_reports { 0 }
    ask_reports { 0 }
  end
end
