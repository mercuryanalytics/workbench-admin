# frozen_string_literal: true

class LocateInvoiceForProject
  include Interactor

  # parameters
  delegate :project_name, to: :context

  delegate :realm, to: IntuitAccount

  def call
    account.with_token do |token|
      data = authorized_service(token, Quickbooks::Service::Customer)
             .query(customer_query)

      id = case data.count
           when 0
             context.fail!(reason: "Not found")
           when 1
             data.first.id
           else
             context.fail!(reason: "Ambiguous")
           end

      invoices = authorized_service(token, Quickbooks::Service::Invoice)
                 .find_by(:customer_ref, id)

      context.fail!(reason: "Not invoiced") if invoices.count.zero?

      context.invoice = invoices.first
    end
  end

  private

  def authorized_service(token, klass)
    klass.new.tap do |result|
      result.company_id = realm
      result.access_token = token
    end
  end

  def query_builder
    @query_builder ||= Quickbooks::Util::QueryBuilder.new
  end

  def customer_query
    clause = query_builder.clause("DisplayName", "LIKE", "#{project_name} %")
    "SELECT Id, DisplayName FROM Customer WHERE #{clause} MAXRESULTS 2"
  end

  def account
    IntuitAccount.instance
  end
end
