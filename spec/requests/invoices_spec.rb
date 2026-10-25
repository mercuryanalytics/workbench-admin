# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Invoices", type: :request do
  describe "GET /invoices/:id" do
    context "without a stored access token" do
      it "redirects to Intuit's grant URL", :aggregate_failures do
        get invoice_path("Project 1")

        expect(response).to have_http_status(:found)
        expect(response.location).to start_with("https://appcenter.intuit.com/connect/oauth2")
      end
    end

    context "with a stored access token" do
      let(:invoice) do
        instance_double(Quickbooks::Model::Invoice,
                        customer_ref: instance_double(Quickbooks::Model::BaseReference, name: "Acme"))
      end

      before { create(:intuit_account) }

      it "renders the customer name", :aggregate_failures do
        allow(LocateInvoiceForProject).to receive(:call).and_return(Interactor::Context.build(invoice:))
        get invoice_path("Project 1")

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq "Acme"
      end

      it "sends the user back to Intuit when the grant has been revoked", :aggregate_failures do
        allow(LocateInvoiceForProject).to receive(:call).and_raise(QuickbooksOauth::ReauthorizationRequired)

        get invoice_path("Project 1")

        expect(response).to have_http_status(:found)
        expect(response.location).to start_with("https://appcenter.intuit.com/connect/oauth2")
      end

      it "responds 409 when the project name is ambiguous" do
        allow(LocateInvoiceForProject).to receive(:call).and_return(failed_context(:ambiguous))

        get invoice_path("Project 1")

        expect(response).to have_http_status(:conflict)
      end

      %i[not_found not_invoiced].each do |reason|
        it "responds 404 when #{reason}" do
          allow(LocateInvoiceForProject).to receive(:call).and_return(failed_context(reason))

          get invoice_path("Project 1")

          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  it "redirects the root to the public website" do
    get root_path

    expect(response).to redirect_to("https://researchresultswebsite.com")
  end

  it "serves the QuickBooks terms of service" do
    get integration_qb_tos_path

    expect(response).to have_http_status(:ok)
  end

  it "serves the QuickBooks privacy policy" do
    get integration_qb_privacy_path

    expect(response).to have_http_status(:ok)
  end

  def failed_context(reason)
    Interactor::Context.build(reason:).tap(&:fail!)
  rescue Interactor::Failure => e
    e.context
  end
end
