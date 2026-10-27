# frozen_string_literal: true

class LocateInvoiceForProject
  include Interactor

  # parameters
  delegate :project_name, to: :context

  delegate :realm, to: IntuitAccount

  def call
    account.with_token do |token|
      data = with_service(token, Quickbooks::Service::Customer) { |service| service.query(customer_query) }

      id = case data.count
           when 0
             context.fail!(reason: :not_found)
           when 1
             data.first.id
           else
             context.fail!(reason: :ambiguous)
           end

      invoices = with_service(token, Quickbooks::Service::Invoice) { |service| service.find_by(:customer_ref, id) }

      # Quickbooks::Collection has no empty?; its count is an attribute.
      context.fail!(reason: :not_invoiced) if invoices.count.zero? # rubocop:disable Style/CollectionQuerying

      context.invoice = invoices.first
    end
  end

  private

  # Logs Intuit's request id, which support needs to trace a call. It is an opaque id, not QuickBooks data.
  def with_service(token, klass)
    service = authorized_service(token, klass)
    yield service
  ensure
    Rails.logger.info("QuickBooks #{klass.name.demodulize} intuit_tid=#{service&.last_response_intuit_tid}")
  end

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
    # The builder escapes quotes but not backslashes, so a backslash before a quote would cancel the escape.
    name = project_name.gsub("\\") { "\\\\" }
    clause = query_builder.clause("DisplayName", "LIKE", "#{name} %")
    "SELECT Id, DisplayName FROM Customer WHERE #{clause} MAXRESULTS 2"
  end

  def account
    IntuitAccount.instance
  end
end
