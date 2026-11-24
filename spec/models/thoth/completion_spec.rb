# frozen_string_literal: true

require "rails_helper"

RSpec.describe Thoth::Completion do
  describe ".reports" do
    it "keeps only finished deliverables with a user" do
      report = create(:thoth_completion)
      create(:thoth_completion, deliverable: false)
      create(:thoth_completion, status: "error")
      create(:thoth_completion, user: nil)
      expect(described_class.reports).to contain_exactly(report)
    end
  end

  describe ".ask" do
    it "keeps only the Ask MercuryAI models" do
      ask = create(:thoth_completion, metadata: { model: "M2mAskMercuryAIReport" })
      create(:thoth_completion)
      expect(described_class.ask).to contain_exactly(ask)
    end
  end

  describe ".counts_by_email" do
    it "counts reports in the period per lowercased email" do
      create_list(:thoth_completion, 2, user: "Ann@Example.com", created_at: 1.day.ago)
      create(:thoth_completion, user: "ann@example.com", created_at: 10.days.ago)
      create(:thoth_completion, user: "bob@example.com", created_at: 1.day.ago)
      expect(described_class.counts_by_email(1.week.ago..)).to eq "ann@example.com" => 2, "bob@example.com" => 1
    end

    it "can be narrowed to Ask MercuryAI reports" do
      create(:thoth_completion, user: "ann@example.com", metadata: { model: "AskMercuryAITopline" })
      create(:thoth_completion, user: "ann@example.com")
      expect(described_class.ask.counts_by_email(1.week.ago..)).to eq "ann@example.com" => 1
    end
  end
end
