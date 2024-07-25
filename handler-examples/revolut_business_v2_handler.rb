# This is for Revolut V2 API for webhooks - https://developer.revolut.com/docs/business/webhooks-v-2
class RevolutBusinessV2Handler < Munster::BaseHandler
  def valid?(request)
    # 1 - Validate the timestamp of the request. Prevent replay attacks.
    # "To validate the event, make sure that the Revolut-Request-Timestamp date-time is within a 5-minute time tolerance of the current universal time (UTC)".
    # Their examples list `timestamp = '1683650202360'` as a sample value, so their timestamp is in millis - not in seconds
    timestamp_str_from_headers = request.headers["HTTP_REVOLUT_REQUEST_TIMESTAMP"]
    delta_t_seconds = (timestamp_str_from_headers / 1000) - Time.now.to_i
    return false unless delta_t_seconds.abs < (5 * 60)

    # 2 - Validate the signature
    # https://developer.revolut.com/docs/guides/manage-accounts/tutorials/work-with-webhooks/verify-the-payload-signature
    string_to_sign = [
      "v1",
      timestamp_str_from_headers,
      request.body.read
    ].join(".")
    computed_signature = "v1=" + OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secrets.revolut_business_webhook_signing_key, string_to_sign)
    # Note: "This means that in the period when multiple signing secrets remain valid, multiple signatures are sent."
    # https://developer.revolut.com/docs/guides/manage-accounts/tutorials/work-with-webhooks/manage-webhooks#rotate-a-webhook-signing-secret
    # https://developer.revolut.com/docs/guides/manage-accounts/tutorials/work-with-webhooks/about-webhooks#security
    # An HTTP header may contain multiple values if it gets sent multiple times. But it does mean we need to test for multiple provided
    # signatures in case of rotation.
    provided_signatures = request.headers["HTTP_REVOLUT_SIGNATURE"].split(",")
    # Use #select instead of `find` to compare all signatures even if only one matches - this to avoid timing leaks.
    # Small effort but might be useful.
    matches = provided_signatures.select do |provided_signature|
      ActiveSupport::SecurityUtils.secure_compare(provided_signature, computed_signature)
    end
    matches.any?
  end

  def self.process(webhook)
    Rails.logger.info { "Processing Revolut webhook #{webhook.body.inspect}" }
  end

  def self.extract_event_id_from_request(action_dispatch_request)
    # The event ID is only available when you retrieve the failed webhooks, which is sad.
    # We can divinate a synthetic ID though by taking a hash of the entire payload though.
    Digest::SHA256.hexdigest(action_dispatch_request.body.read)
  end
end
