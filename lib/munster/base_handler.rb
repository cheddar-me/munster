# frozen_string_literal: true

require_relative "jobs/processing_job"

module Munster
  class BaseHandler
    # Gets called from the background job
    def self.process(...)
      new.process(...)
    end

    # Reimplement this method, it's being used in WebhooksController to store incoming webhook.
    # Also que for processing in the end.
    # @return [void]
    def handle(action_dispatch_request)
      binary_body_str = action_dispatch_request.body.read.force_encoding(Encoding::BINARY)
      attrs = {
        body: binary_body_str,
        handler_module_name: self.class.name,
        handler_event_id: extract_event_id_from_request(action_dispatch_request)
      }
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
