# frozen_string_literal: true

# Intuit's OAuth endpoints, read from its discovery documents so a change on their side is picked up without a deploy.
# If a document can't be fetched, the last known endpoints are used instead.
class IntuitDiscovery
  DOCUMENTS = {
    live: "https://developer.api.intuit.com/.well-known/openid_configuration",
    sandbox: "https://developer.api.intuit.com/.well-known/openid_sandbox_configuration"
  }.freeze
  FALLBACK = {
    "authorization_endpoint" => "https://appcenter.intuit.com/connect/oauth2",
    "token_endpoint" => "https://oauth.platform.intuit.com/oauth2/v1/tokens/bearer"
  }.freeze
  REFRESH_AFTER = 1.day
  RETRY_AFTER = 5.minutes

  class << self
    def endpoints(app)
      entry = cache[app]
      return entry[:document] if entry && entry[:expires_at] > Time.current

      fetch(app)
    end

    def reset!
      @cache = nil
    end

    private

    def cache
      @cache ||= {}
    end

    def fetch(app)
      document = FALLBACK.merge(read(DOCUMENTS.fetch(app)).slice(*FALLBACK.keys))
      cache[app] = { document:, expires_at: REFRESH_AFTER.from_now }
      document
    rescue Faraday::Error, JSON::ParserError => e
      Rails.logger.warn { "Intuit discovery document unavailable (#{e.class}); using the last known endpoints" }
      cache[app] = { document: FALLBACK, expires_at: RETRY_AFTER.from_now }
      FALLBACK
    end

    def read(url)
      response = Faraday.new(request: { timeout: 3, open_timeout: 3 }).get(url)
      raise Faraday::ServerError, "status #{response.status}" unless response.success?

      JSON.parse(response.body)
    end
  end
end
