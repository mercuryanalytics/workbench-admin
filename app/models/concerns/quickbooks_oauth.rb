# frozen_string_literal: true

module QuickbooksOauth
  extend ActiveSupport::Concern

  # Intuit no longer honours the stored grant (revoked by the user, or expired), so the user must authorize again.
  class ReauthorizationRequired < RuntimeError; end

  included do
    delegate :oauth_client, to: :class
  end

  def refresh_token!
    refresh_token = oauth_access_token.refresh!
    update_from(refresh_token)
  rescue OAuth2::Error => e
    raise ReauthorizationRequired, e.code if e.code == "invalid_grant"

    raise
  end

  def save_token_from_code(code, redirect_uri)
    resp = oauth_client.auth_code.get_token(code, redirect_uri:)
    update_from(resp) if resp
  end

  def update_from(oauth_token)
    access_token = oauth_token.token
    expires_at = Time.at(oauth_token.expires_at).utc
    refresh_token = oauth_token.refresh_token
    refresh_expires_at = [refresh_token["x_refresh_token_expires_in"].to_i.seconds, 100.days].max
    update!(access_token:, expires_at:, refresh_token:, refresh_expires_at:)
  end

  def grant_url(redirect_uri, state:)
    oauth_client.auth_code.authorize_url(
      redirect_uri:,
      response_type: "code",
      state:,
      scope: "com.intuit.quickbooks.accounting"
    )
  end

  def oauth_access_token
    OAuth2::AccessToken.new(oauth_client, access_token, refresh_token:)
  end

  module ClassMethods
    # Built per call, not memoized, so the endpoints follow the (cached) discovery document.
    def oauth_client
      OAuth2::Client.new(oauth_client_id, oauth_client_secret, oauth_options)
    end

    # Credentials pick the Intuit app per environment; staging uses :sandbox until its live keys are unlocked.
    def intuit_app
      Rails.application.credentials.intuit_app&.to_sym || :live
    end

    def oauth_credentials
      Rails.application.credentials.intuit[intuit_app]
    end

    def realm
      oauth_credentials.realm_id
    end

    def oauth_client_id
      oauth_credentials.client_id
    end

    def oauth_client_secret
      oauth_credentials.client_secret
    end

    def oauth_options
      endpoints = IntuitDiscovery.endpoints(intuit_app)
      {
        site: endpoints["authorization_endpoint"],
        authorize_url: endpoints["authorization_endpoint"],
        token_url: endpoints["token_endpoint"]
      }
    end
  end
end
