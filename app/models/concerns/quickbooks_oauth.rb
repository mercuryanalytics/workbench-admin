# frozen_string_literal: true

module QuickbooksOauth
  extend ActiveSupport::Concern

  def refresh_token!
    refresh_token = oauth_access_token.refresh!
    update_from(refresh_token)
  end

  def save_token_from_code(code, redirect_uri)
    resp = oauth_client.auth_code.get_token(code, redirect_uri:)
    update_from(resp) if resp
  end

  def update_from(oauth_token)
    Rails.logger.debug { "update_from #{oauth_token.inspect}" }
    access_token = oauth_token.token
    expires_at = Time.at(oauth_token.expires_at).utc
    refresh_token = oauth_token.refresh_token
    refresh_expires_at = [refresh_token["x_refresh_token_expires_in"].to_i.seconds, 100.days].max
    update!(access_token:, expires_at:, refresh_token:, refresh_expires_at:)
  end

  def grant_url(redirect_uri)
    oauth_client.auth_code.authorize_url(
      redirect_uri:,
      response_type: "code",
      state: SecureRandom.hex(12),
      scope: "com.intuit.quickbooks.accounting"
    )
  end

  def oauth_access_token
    OAuth2::AccessToken.new(oauth_client, access_token, refresh_token:)
  end

  def oauth_client
    @oauth_client ||= self.class.oauth_client
  end

  INTUIT_AUTH_URL = "https://appcenter.intuit.com/connect/oauth2"
  INTUIT_TOKEN_URL = "https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer"
  module ClassMethods
    def oauth_client
      @oauth_client ||= OAuth2::Client.new(oauth_client_id, oauth_client_secret, oauth_options)
    end

    def intuit_app
      :live
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
      {
        site: INTUIT_AUTH_URL,
        authorize_url: INTUIT_AUTH_URL,
        token_url: INTUIT_TOKEN_URL
      }
    end
  end
end
