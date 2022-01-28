# frozen_string_literal: true

class ApplicationController < ActionController::Base
  def intuit_authenticate
    session[:target] = params[:id]
    redirect_to account.grant_url(api_oauth_callback_url), allow_other_host: true
  end

  def acquire_token
    token = IntuitAccount.instance
    Rails.logger.debug { "Access token: #{token.access_token.inspect}" }
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
