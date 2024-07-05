# frozen_string_literal: true

require "active_job" if defined?(Rails)

module Munster
  class ProcessingJob < ActiveJob::Base
    MISSING_HEADERS_COLUMN_ERROR = <<~EOS
      The webhook handler validates asynchronously, but there is no column in the database to save the headers in.
      Webhook signatures (which you usually want to validate) will normally be injected into the webhook request headers,
      in the form of an "X-Signature" header or similar. You need to run the migration to add the column to the
      `received_webhooks' table before you will be able to use async validation.
    EOS

    MISSING_HEADERS_ERROR = <<~EOS
      The webhook handler validates asynchronously, but there were no request headers saved with the webhook
      You need to ensure you validate inline (`validate_async?` should return "false") until you have ensured
      that all webhooks that will be getting processed are getting saved with the request headers intact.
    EOS

    def perform(webhook)
      if valid?(webhook)
        # TODO: there should be some sort of locking or concurrency control here, but it's outside of
        # Munsters scope of responsibility. Developer implementing this should decide how this should be handled.
        webhook.handler.process(webhook)
        # TODO: remove process attribute
      else
        Rails.logger.info { "Webhook #{webhook.inspect} did not pass validation and was skipped" }
        webhook.skipped!
      end
    end

    def valid?(webhook)
      return true unless webhook.handler.validate_async?

      raise MISSING_HEADERS_COLUMN_ERROR unless webhook.class.column_names.include?("request_headers")
      raise MISSING_HEADERS_ERROR if webhook.request_headers.blank?

      revived_action_dispatch_request = Munster.header_hash_and_body_to_action_dispatch_request(webhook.request_headers, webhook.body)
      webhook.handler.new.valid?(revived_action_dispatch_request)
    end
  end
end
