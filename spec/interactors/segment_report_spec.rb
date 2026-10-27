# frozen_string_literal: true

require "rails_helper"

RSpec.describe SegmentReport do
  subject(:rows) { described_class.call(period:).rows.index_by(&:account) }

  let(:period) { 1.week.ago.. }

  def join(client, email:, last_login: nil)
    create(:petasos_membership, client:, user: create(:petasos_user, email:, last_login:))
  end

  def complete(email, model: "ShortSummary", **)
    create(:thoth_completion, user: email, metadata: { model: }, created_at: 1.day.ago, **)
  end

  describe "segments" do
    before do
      %w[Dormant Active Activated Power].each do |name|
        join(create(:petasos_client, name:), email: "#{name.downcase}@example.com")
      end
      Petasos::User.find_by!(email: "active@example.com").update!(last_login: 1.day.ago)
      complete("activated@example.com")
      complete("power@example.com", model: "AskMercuryAITopline")
    end

    it "gives each account its highest segment" do
      expect(rows.transform_values(&:segment)).to eq "Dormant" => :dormant, "Active" => :active,
                                                     "Activated" => :activated, "Power" => :power
    end
  end

  context "with a client of several users" do
    before do
      client = create(:petasos_client, name: "Acme")
      join(client, email: "ann@example.com", last_login: 1.day.ago)
      join(client, email: "bob@example.com", last_login: 3.weeks.ago)
      complete("ann@example.com")
      complete("bob@example.com", model: "M2mAskMercuryAIReport")
      create(:petasos_project, client:, project_number: "P42")
    end

    it "rolls the users up to the account" do
      expect(rows["Acme"]).to have_attributes(users: 2, logins: 1, mercury_ai_reports: 1, ask_reports: 1,
                                              last_project: "P42")
    end
  end

  describe "segment change" do
    let(:period) { Date.new(2026, 10, 19).in_time_zone.all_week }
    let(:client) { create(:petasos_client, name: "Acme") }

    before do
      join(client, email: "ann@example.com", last_login: Date.new(2026, 10, 20))
      create(:account_week, client_id: client.id, week: Date.new(2026, 10, 12), segment: previous)
    end

    context "when the account moved up" do
      let(:previous) { "dormant" }

      it { expect(rows["Acme"]).to have_attributes(previous_segment: :dormant, segment: :active, segment_change: :up) }
    end

    context "when the account moved down" do
      let(:previous) { "power" }

      it { expect(rows["Acme"]).to have_attributes(segment_change: :down) }
    end

    context "when the account stayed put" do
      let(:previous) { "active" }

      it { expect(rows["Acme"]).to have_attributes(segment_change: :same) }
    end

    context "when there is no row for the week before" do
      let(:previous) { "active" }

      before { AccountWeek.update_all(week: Date.new(2026, 10, 5)) } # rubocop:disable Rails/SkipsModelValidations

      it { expect(rows["Acme"]).to have_attributes(previous_segment: nil, segment_change: nil) }
    end
  end

  describe ".csv" do
    it "has a header and a line per account" do
      create(:petasos_client, name: "Acme")
      lines = described_class.csv(described_class.call(period:).rows).lines
      expect(lines.map(&:chomp)).to eq ["client_id,account,users,logins,mercury_ai_reports,ask_reports,last_project," \
                                        "segment,previous_segment,segment_change",
                                        "#{Petasos::Client.first.id},Acme,0,0,0,0,,dormant,,"]
    end
  end

  it "counts a user in every client they belong to" do
    user = create(:petasos_user, last_login: 1.day.ago)
    create_list(:petasos_membership, 2, user:)
    expect(rows.values.map(&:logins)).to eq [1, 1]
  end

  it "reports an account with no users as dormant" do
    create(:petasos_client, name: "Empty")
    expect(rows["Empty"]).to have_attributes(users: 0, segment: :dormant, last_project: nil)
  end
end
