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

  describe "user rows" do
    subject(:user_rows) { described_class.call(period:).user_rows }

    before do
      client = create(:petasos_client, name: "Acme")
      join(client, email: "bob@example.com", last_login: 3.weeks.ago)
      join(client, email: "ann@example.com", last_login: 1.day.ago)
      join(client, email: "new@example.com")
      complete("ann@example.com")
      complete("ann@example.com", model: "AskMercuryAITopline")
    end

    it "has a row per member under the account, by email" do
      expect(user_rows.map(&:user)).to eq %w[ann@example.com bob@example.com new@example.com]
    end

    it "gives each member their own counts and segment" do
      expect(user_rows.map { |row| row.to_h.slice(:logins, :mercury_ai_reports, :ask_reports, :segment).values })
        .to eq [[1, 1, 1, :power], [0, 0, 0, :dormant], [0, 0, 0, :dormant]]
    end

    it "shows the last login as a date, or nothing for a user who never logged in" do
      expect(user_rows.map(&:last_login)).to eq [1.day.ago.to_date, 3.weeks.ago.to_date, nil]
    end

    it "adds up to the account row" do
      account = described_class.call(period:).rows.first
      expect(user_rows.sum(&:logins)).to eq account.logins
    end
  end

  describe ".csv" do
    let(:result) { described_class.call(period:) }
    let(:lines) { described_class.csv(result.rows, result.user_rows).lines.map(&:chomp) }
    let(:client) { create(:petasos_client, name: "Acme") }

    it "has a header" do
      expect(lines.first).to eq "level,client_id,account,user,users,last_login,logins,mercury_ai_reports,ask_reports," \
                                "last_project,segment,previous_segment,segment_change"
    end

    it "puts an account line, then its users underneath" do
      join(client, email: "ann@example.com", last_login: Date.new(2026, 10, 20))
      expect(lines.drop(1)).to eq ["account,#{client.id},Acme,,1,,0,0,0,,dormant,,",
                                   "user,#{client.id},Acme,ann@example.com,,2026-10-20,0,0,0,,dormant,,"]
    end

    it "has just an account line for an account without users" do
      client
      expect(lines.size).to eq 2
    end
  end

  describe ".csv with a name a spreadsheet would run as a formula" do
    it "writes it as text" do
      create(:petasos_client, name: "=HYPERLINK(\"http://example.com\")")
      result = described_class.call(period:)
      expect(described_class.csv(result.rows, result.user_rows)).to include(",\"'=HYPERLINK(")
    end

    it "writes a user's email as text" do
      join(create(:petasos_client), email: "+1@example.com")
      result = described_class.call(period:)
      expect(described_class.csv(result.rows, result.user_rows)).to include(",'+1@example.com,")
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
