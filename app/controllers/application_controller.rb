# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Responses carry QuickBooks customer data, and Intuit requires no-store on pages with sensitive data.
  before_action { response.cache_control.merge!(no_store: true) }

  def intuit_authenticate
    session[:target] = params[:id]
    redirect_to account.grant_url(api_oauth_callback_url), allow_other_host: true
  end

  def acquire_token
    token = IntuitAccount.instance
    return if token.access_token

    redirect_to token.grant_url(api_oauth_callback_url), allow_other_host: true
  end

  def intuit_callback
    # can use params[:state] to retrieve user information

    account.save_token_from_code(params[:code], api_oauth_callback_url)
    redirect_to invoice_path(session[:target])
  end

  def account
    IntuitAccount.instance
  end
end
