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

  describe ".call" do
    let(:customer_service) { service_double(query: [instance_double(Quickbooks::Model::Customer, id: "7")], tid: "tid-1") }
    let(:invoice_service) { service_double(find_by: [:invoice], tid: "tid-2") }

    before do
      allow(IntuitAccount.instance).to receive(:with_token).and_yield("token")
      allow(Quickbooks::Service::Customer).to receive(:new).and_return(customer_service)
      allow(Quickbooks::Service::Invoice).to receive(:new).and_return(invoice_service)
      allow(Rails.logger).to receive(:info)
    end

    it "logs the intuit_tid of each QuickBooks call", :aggregate_failures do
      described_class.call(project_name: "Acme")

      expect(Rails.logger).to have_received(:info).with("QuickBooks Customer intuit_tid=tid-1")
      expect(Rails.logger).to have_received(:info).with("QuickBooks Invoice intuit_tid=tid-2")
    end

    it "logs the intuit_tid when the call raises" do
      allow(customer_service).to receive(:query).and_raise(Quickbooks::IntuitRequestException, "bad")

      described_class.call(project_name: "Acme") rescue nil # rubocop:disable Style/RescueModifier

      expect(Rails.logger).to have_received(:info).with("QuickBooks Customer intuit_tid=tid-1")
    end

    def service_double(tid:, **calls)
      instance_double(Quickbooks::Service::BaseService, :company_id= => nil, :access_token= => nil,
                                                        last_response_intuit_tid: tid, **calls)
    end
  end
end
