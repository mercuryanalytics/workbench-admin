# frozen_string_literal: true

FactoryBot.define do
  factory :segment_user_row, class: "SegmentReport::UserRow" do
    sequence(:client_id)
    account { "Acme" }
    sequence(:user) { |n| "user#{n}@example.com" }
    last_login { nil }
    logins { 0 }
    mercury_ai_reports { 0 }
    ask_reports { 0 }
    segment { :dormant }

    initialize_with { new(**attributes) }
  end
end
