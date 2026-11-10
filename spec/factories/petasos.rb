# frozen_string_literal: true

FactoryBot.define do
  factory :petasos_client, class: "Petasos::Client" do
    sequence(:name) { |n| "Client #{n}" }
  end

  factory :petasos_user, class: "Petasos::User" do
    sequence(:email) { |n| "user#{n}@example.com" }
    last_login { nil }
  end

  factory :petasos_membership, class: "Petasos::Membership" do
    client factory: :petasos_client
    user factory: :petasos_user
  end

  factory :petasos_project, class: "Petasos::Project" do
    client factory: :petasos_client
    sequence(:name) { |n| "Project #{n}" }
    sequence(:project_number) { |n| "P#{n}" }
  end
end
