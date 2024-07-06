# frozen_string_literal: true

require "active_job" if defined?(Rails)

module Munster
  class ProcessingJob < ActiveJob::Base

    def perform(webhook)
      if valid?(webhook)
        # TODO: there should be some sort of locking or concurrency control here, but it's outside of
        # Munsters scope of responsibility. Developer implementing this should decide how this should be handled.
        webhook.handler.process(webhook)
        # TODO: remove process attribute
      else
        Rails.logger.info { "Webhook #{webhook.inspect} did not pass validation and was skipped" }
        webhook.failed_validation!
      end
    end

    def valid?(webhook)
      return true unless webhook.handler.validate_async?
      webhook.handler.valid?(webhook.request)
    end
  end
end
