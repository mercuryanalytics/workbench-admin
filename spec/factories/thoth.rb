# frozen_string_literal: true

FactoryBot.define do
  factory :thoth_completion, class: "Thoth::Completion" do
    sequence(:project) { |n| "project-#{n}" }
    user { "user@example.com" }
    deliverable { true }
    status { "ready" }
    metadata { { model: "ShortSummary" } }
  end
end
