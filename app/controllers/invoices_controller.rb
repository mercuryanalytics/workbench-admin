# frozen_string_literal: true

class InvoicesController < ApplicationController
  before_action :acquire_token

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
