# frozen_string_literal: true

require "rails_helper"

RSpec.describe Petasos::Project do
  describe ".latest_numbers_by_client" do
    subject(:client) { create(:petasos_client) }

    it "maps each client to its most recently updated project" do
      create(:petasos_project, client:, project_number: "OLD", updated_at: 2.days.ago)
      create(:petasos_project, client:, project_number: "NEW", updated_at: 1.day.ago)
      expect(described_class.latest_numbers_by_client).to eq client.id => "NEW"
    end
  end
end
