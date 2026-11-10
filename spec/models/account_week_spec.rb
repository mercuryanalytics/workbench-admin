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

    context "when the week is already recorded" do
      before { create(:account_week, client_id: 7, week:, segment: "dormant") }

      it "refuses to replace it" do
        expect { described_class.record(rows, week:) }.to raise_error(described_class::AlreadyRecorded)
      end

      it "keeps the stored row" do
        described_class.record(rows, week:) rescue nil # rubocop:disable Style/RescueModifier
        expect(described_class.find_by!(client_id: 7, week:).segment).to eq "dormant"
      end

      it "replaces it when forced" do
        described_class.record(rows, week:, force: true)
        expect(described_class.where(client_id: 7, week:).pluck(:segment)).to eq %w[activated]
      end
    end
  end

  describe ".prune" do
    let(:week) { Date.new(2026, 10, 19) }

    it "deletes weeks older than the retention window and keeps the rest" do
      create(:account_week, week: week - 15.weeks)
      kept = [create(:account_week, week: week - 14.weeks), create(:account_week, week: week + 1.week)]
      described_class.prune(week:, keep: 14)
      expect(described_class.all).to match_array(kept)
    end
  end
end
