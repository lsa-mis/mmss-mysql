# frozen_string_literal: true

# HTTP Basic Auth for Letter Opener Web on staging only (see config/environments/staging.rb).
# Set LETTER_OPENER_WEB_HTTP_BASIC_USER and LETTER_OPENER_WEB_HTTP_BASIC_PASSWORD on the server.
# If either is unset, requests pass through (use network restrictions instead).
class LetterOpenerWebBasicAuth
  def initialize(app)
    @app = app
  end

  def call(env)
    path = env["PATH_INFO"]
    return @app.call(env) unless path&.start_with?("/letter_opener")

    user = ENV["LETTER_OPENER_WEB_HTTP_BASIC_USER"].to_s
    pass = ENV["LETTER_OPENER_WEB_HTTP_BASIC_PASSWORD"].to_s
    if user.empty? || pass.empty?
      Rails.logger.warn(
        "[LetterOpenerWeb] LETTER_OPENER_WEB_HTTP_BASIC_USER/PASSWORD not set; /letter_opener is not protected by HTTP basic auth."
      )
      return @app.call(env)
    end

    auth = Rack::Auth::Basic::Request.new(env)
    if auth.provided? && auth.basic? && auth.credentials &&
        secure_digest_compare(auth.credentials[0], user) &&
        secure_digest_compare(auth.credentials[1], pass)
      @app.call(env)
    else
      unauthorized
    end
  end

  private

  def secure_digest_compare(given, expected)
    ActiveSupport::SecurityUtils.secure_compare(
      ::Digest::SHA256.hexdigest(given.to_s),
      ::Digest::SHA256.hexdigest(expected.to_s)
    )
  end

  def unauthorized
    body = "Unauthorized"
    [
      401,
      {
        "Content-Type" => "text/plain",
        "Content-Length" => body.bytesize.to_s,
        "WWW-Authenticate" => 'Basic realm="Letter Opener Web"'
      },
      [body]
    ]
  end
end
