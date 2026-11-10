# frozen_string_literal: true

FactoryBot.define do
  factory :segment_row, class: "SegmentReport::Row" do
    sequence(:client_id)
    account { "Acme" }
    users { 1 }
    logins { 0 }
    mercury_ai_reports { 0 }
    ask_reports { 0 }
    last_project { nil }
    segment { :dormant }
    previous_segment { nil }
    segment_change { nil }

    initialize_with { new(**attributes) }
  end
end
