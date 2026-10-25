# frozen_string_literal: true

class InvoicesController < ApplicationController
  before_action :acquire_token

  # Rejected queries, throttling and outages. Log the class only: the message can carry QuickBooks data.
  rescue_from Quickbooks::Error do |error|
    logger.warn("QuickBooks request failed: #{error.class}")
    render plain: "QuickBooks could not process the request.", status: :bad_gateway
  end

  def show
    res = LocateInvoiceForProject.call(project_name: params[:id])
    if res.failure?
      case res.reason
      when :ambiguous
        render plain: "Multiple invoices found", status: :conflict
      else
        render plain: "Invoice not found", status: :not_found
      end
    else
      render plain: res.invoice.customer_ref.name
    end
  end
end
