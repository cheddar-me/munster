# This is an example handler for Customer.io reporting webhooks. You
# can find more documentation here https://customer.io/docs/api/webhooks/#operation/reportingWebhook
class Webhooks::CustomerIoHandler < Munster::BaseHandler
  def process(webhook)
    json = JSON.parse(webhook.body, symbolize_names: true)
    case json[:metric]
    when "subscribed"
      # ...
    when "unsubscribed"
      # ...
    when "cio_subscription_preferences_changed"
      # ...
    end
  end

  def extract_event_id_from_request(action_dispatch_request)
    action_dispatch_request.params.fetch(:event_id)
  end

  # Verify that request is actually comming from customer.io here
  # @see https://customer.io/docs/api/webhooks/#section/Securely-Verifying-Requests
  #
  # - Should have "X-CIO-Signature", "X-CIO-Timestamp" headers.
  # - Combine the version number, timestamp and body delimited by colons to form a string in the form v0:<timestamp>:<body>
  # - Using HMAC-SHA256, hash the string using your webhook signing secret as the hash key.
  # - Compare this value to the value of the X-CIO-Signature header sent with the request to confirm
  def valid?(action_dispatch_request)
    signing_key = Rails.application.secrets.customer_io_webhook_signing_key
    xcio_signature = action_dispatch_request.headers["HTTP_X_CIO_SIGNATURE"]
    xcio_timestamp = action_dispatch_request.headers["HTTP_X_CIO_TIMESTAMP"]
    request_body = action_dispatch_request.body.read
    string_to_sign = "v0:#{xcio_timestamp}:#{request_body}"
    hmac = OpenSSL::HMAC.hexdigest("SHA256", signing_key, string_to_sign)
    Rack::Utils.secure_compare(hmac, xcio_signature)
  end
end
