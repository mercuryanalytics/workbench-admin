# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReportMailer do
  describe "#weekly" do
    subject(:mail) { described_class.weekly(rows:, period: Date.new(2026, 10, 19).in_time_zone.all_week) }

    let(:rows) do
      [
        build(:segment_row, segment: :power, segment_change: :up),
        build(:segment_row, segment: :dormant, segment_change: :down),
        build(:segment_row, segment: :dormant, segment_change: nil)
      ]
    end

    before do
      allow(Rails.application.credentials).to receive(:dig).and_call_original
      credentials = Rails.application.credentials
      allow(credentials).to receive(:dig).with(:report, :recipients).and_return(["scottb@example.com"])
      allow(credentials).to receive(:dig).with(:smtp, :from).and_return("reports@example.com")
    end

    it "is addressed from the credentials" do
      expect(mail).to have_attributes(to: ["scottb@example.com"], from: ["reports@example.com"],
                                      subject: "Platform engagement, week of 2026-10-19")
    end

    it "attaches the CSV" do
      expect(mail.attachments["segments-2026-10-19.csv"].body.to_s).to eq SegmentReport.csv(rows)
    end

    it "summarizes the segments and moves" do
      expect(mail.text_part.body.to_s).to include("Power: 1", "Dormant: 2", "Moved up: 1, moved down: 1")
    end
  end
end
