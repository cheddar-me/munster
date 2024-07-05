# frozen_string_literal: true

require_relative "jobs/processing_job"

module Munster
  class BaseHandler
    # `handle` accepts the ActionDispatch HTTP request and saves the webhook for later processing. It then
    # enqueues an ActiveJob which will perform the processing using `process`.
    #
    # @param action_dispatch_request[ActionDispatch::Request] the request from the controller
    # @return [void]
    def handle(action_dispatch_request)
      handler_module_name = is_a?(Munster::BaseHandler) ? self.class.name : to_s
      handler_event_id = extract_event_id_from_request(action_dispatch_request)

      webhook = Munster::ReceivedWebhook.new(handler_event_id: handler_event_id, handler_module_name: handler_module_name)
      webhook.assign_from_request(action_dispatch_request)
      webhook.save!

      Munster.configuration.processing_job_class.perform_later(webhook)
    rescue ActiveRecord::RecordNotUnique # Webhook deduplicated
      Rails.logger.info { "#{inspect} Webhook #{handler_event_id} is a duplicate delivery and will not be stored." }
    end

    # This is the heart of your webhook processing. Override this method and define your processing inside of it.
    #
    # @param received_webhook[Munster::ReceivedWebhook]
    def process(received_webhook)
    end

    # This method verifies that request is not malformed and actually comes from the webhook sender:
    # signature validation, HTTP authentication, IP whitelisting and the like. Depending on whether you validate
    # sync or async, the `action_dispatch_request` may be a reconstructed HTTP request (but most of Rails methods
    # will still be available on it).
    #
    # @param action_dispatch_request[ActionDispatch::Request] the request from the controller
    # @return [Boolean]
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
    #
    # To preserve backwards compatibility with our own handlers we already have,
    # we default it to `false`. The default is going to be `true` in future versions of Munster.
    #
    # @return [Boolean]
    def validate_async?
      false
    end

    # Default implementation just generates UUID, but if the webhook sender sends us
    # an event ID we use it for deduplication. A duplicate webhook is not going to be
    # stored in the database if it is already present there.
    #
    # @return [String]
    def extract_event_id_from_request(action_dispatch_request)
      SecureRandom.uuid
    end

    # Webhook senders have varying retry behaviors, and often you want to "pretend"
    # everything is fine even though there is an error so that they keep sending you
    # data and do not disable your endpoint forcibly. We allow this to be configured
    # on a per-handler basis - a better webhooks sender will be able to make out
    # some sense of the errors.
    #
    # @return [Boolean]
    def expose_errors_to_sender?
      true
    end

    # Tells the controller whether this handler is active or not. This can be used
    # to deactivate a particular handler via feature flags for example, or use other
    # logic to determine whether the handler may be used to create new received webhooks
    # in the system. This is primarily needed for load shedding.
    #
    # @return [Boolean]
    def active?
      true
    end
  end
end
