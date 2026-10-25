# frozen_string_literal: true

require "rails_helper"

RSpec.describe LocateInvoiceForProject do
  describe "#customer_query" do
    def query_for(name)
      described_class.new(project_name: name).send(:customer_query)
    end

    it "escapes single quotes" do
      expect(query_for("O'Brien")).to include("LIKE 'O\\'Brien %'")
    end

    it "escapes a backslash so it cannot cancel the quote escape" do
      expect(query_for("a\\'b")).to include("LIKE 'a\\\\\\'b %'")
    end
  end
end
