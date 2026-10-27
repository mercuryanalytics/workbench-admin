# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccountWeek do
  describe ".record" do
    subject(:rows) { [SegmentReport::Row.new(**attributes)] }

    let(:week) { Date.new(2026, 10, 19) }
    let(:attributes) do
      { client_id: 7, account: "Acme", users: 3, logins: 1, mercury_ai_reports: 2, ask_reports: 0, last_project: "P1",
        segment: :activated, previous_segment: :active, segment_change: :up }
    end

    it "stores the row for the week" do
      described_class.record(rows, week:)
      expect(described_class.find_by!(client_id: 7, week:)).to have_attributes(segment: "activated", users: 3)
    end

    it "replaces the row when the week is recorded again" do
      create(:account_week, client_id: 7, week:, segment: "dormant")
      described_class.record(rows, week:)
      expect(described_class.where(client_id: 7, week:).pluck(:segment)).to eq %w[activated]
    end
  end
end
