# frozen_string_literal: true

# This handler is an example for Starling Payments API,
# you can find the documentation here https://developer.starlingbank.com/payments/docs#account-and-address-structure-1
class StarlingPaymentsHandler < Munster::BaseHandler
  # This method will be used to process webhook by async worker.
  def process(received_webhook)
    Rails.logger.info { received_webhook.body }
  end

  # Starling supplies signatures in the form SHA512(secret + request_body)
  def valid?(action_dispatch_request)
    supplied_signature = action_dispatch_request.headers.fetch("X-Hook-Signature")
    supplied_digest_bytes = Base64.strict_decode64(supplied_signature)
    sha512 = Digest::SHA2.new(512)
    signing_secret = Rails.credentials.starling_payments_webhook_signing_secret
    computed_digest_bytes = sha512.digest(signing_secret.b + action_dispatch_request.body.b)
    ActiveSupport::SecurityUtils.secure_compare(computed_digest_bytes, supplied_digest_bytes)
  end

  # Some Starling webhooks do not provide a notification UID, but for those which do we can deduplicate
  def extract_event_id_from_request(action_dispatch_request)
    action_dispatch_request.params.fetch("notificationUid", SecureRandom.uuid)
  end
end
