# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Responses carry QuickBooks customer data, and Intuit requires no-store on pages with sensitive data.
  before_action { response.cache_control.merge!(no_store: true) }

  rescue_from QuickbooksOauth::ReauthorizationRequired, with: :authorize_with_intuit

  def intuit_authenticate
    authorize_with_intuit
  end

  def acquire_token
    return if IntuitAccount.instance.access_token

    authorize_with_intuit
  end

  def intuit_callback
    # The state we issued with the grant URL must come back, or anyone could link their own company by sending a code.
    expected = session.delete(:oauth_state)
    return head :forbidden unless expected && ActiveSupport::SecurityUtils.secure_compare(expected, params[:state].to_s)

    account.save_token_from_code(params[:code], api_oauth_callback_url)
    target = session.delete(:target)
    target ? redirect_to(invoice_path(target)) : render(plain: "Connected to QuickBooks")
  end

  def account
    IntuitAccount.instance
  end

  private

  def authorize_with_intuit
    # A server-to-server caller can't follow Intuit's consent page, so tell it what is wrong instead.
    unless request.headers["Accept"].to_s.include?("text/html")
      return render plain: "QuickBooks authorization is needed. Contact IT.", status: :service_unavailable
    end

    session[:target] = params[:id]
    session[:oauth_state] = SecureRandom.hex(12)
    redirect_to account.grant_url(api_oauth_callback_url, state: session[:oauth_state]), allow_other_host: true
  end
end
