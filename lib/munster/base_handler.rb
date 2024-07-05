# frozen_string_literal: true

require_relative "jobs/processing_job"

module Munster
  class BaseHandler
    # Reimplement this method, it's being used in WebhooksController to store incoming webhook.
    # Also que for processing in the end.
    # @return [void]
    def handle(action_dispatch_request)
      action_dispatch_request.body.read.force_encoding(Encoding::BINARY)
      request_headers, binary_body_str = Munster.action_dispatch_request_to_header_hash_and_body(action_dispatch_request)
      attrs = {
        body: binary_body_str,
        handler_module_name: self.class.name,
        handler_event_id: extract_event_id_from_request(action_dispatch_request)
      }

      # If the migration hasn't been applied yet, we can't save the headers.
      if Munster::ReceivedWebhook.column_names.include?("request_headers")
        attrs[:request_headers] = request_headers
      else
        Rails.logger.warn { "You need to run Munster migrations so that request headers can be persisted with the model. Async validation is not going to work without that column being set." }
      end

      webhook = Munster::ReceivedWebhook.create!(**attrs)

      Munster.configuration.processing_job_class.perform_later(webhook)
    rescue ActiveRecord::RecordNotUnique # Deduplicated
      nil
    end

    # This method will be used to process webhook by async worker.
    def process(received_webhook)
    end

    # This method verifies that request actually comes from provider:
    # signature validation, HTTP authentication, IP whitelisting and the like
    def valid?(action_dispatch_request)
      true
    end

    # Tells the controller whether this webhook handler desires to perform validation
    # before persisting the webhook or after. When using webhooks which are signed,
    # one of the most frequent mistakes is to forget the credentials (the secret)
    # for generating the webhook signature. If the controller starts rejecting the
    # webhooks outright due to this misconfiguration, they will get missed - which
    # is exactly one of the things Munster needs to prevent. Having a way to choose
    # whether to validate async or inline allows a wrong credential to be added and
    # the webhooks to get processed later. At the same time, if your webhook senders
    # are expected to be very aggressive, you might want to perform this validation
    # upfront, before the webhook gets saved into the database. This prevents malicious
    # senders from spamming your DB and causing a denial-of-service on it. That's why this
    # is made configurable.
    def validate_async?
      false
    end

    # Default implementation just generates UUID, but if the webhook sender sends us
    # an event ID we use it for deduplication.
    def extract_event_id_from_request(action_dispatch_request)
      SecureRandom.uuid
    end

    # Webhook senders have varying retry behaviors, and often you want to "pretend"
    # everything is fine even though there is an error so that they keep sending you
    # data and do not disable your endpoint forcibly. We allow this to be configured
    # on a per-handler basis - a better webhooks sender will be able to make out
    # some sense of the errors.
    def expose_errors_to_sender?
      true
    end

    # Tells the controller whether this handler is active or not. This can be used
    # to deactivate a particular handler via feature flags for example, or use other
    # logic to determine whether the handler may be used to create new received webhooks
    # in the system. This is primarily needed for load shedding.
    def active?
      true
    end
  end
end
