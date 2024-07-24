# frozen_string_literal: true

require "active_job" if defined?(Rails)

module Munster
  class ProcessingJob < ActiveJob::Base
    class WebhookPayloadInvalid < StandardError
    end

    def perform(webhook)
      Rails.error.set_context(munster_handler_module_name: webhook.handler_module_name, **Munster.configuration.error_context)

      webhook.with_lock do
        return unless webhook.received?
        webhook.processing!
      end

      if webhook.handler.valid?(webhook.request)
        webhook.handler.process(webhook)
        webhook.processed! if webhook.processing?
      else
        e = WebhookPayloadInvalid.new("#{webhook.class} #{webhook.id} did not pass validation and was skipped")
        Rails.error.report(e, handled: true, severity: :error)
        webhook.failed_validation!
      end
    rescue => e
      webhook.error!
      raise e
    end
  end
end
