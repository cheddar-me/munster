# frozen_string_literal: true

require "active_job/railtie"

module Munster
  class ProcessingJob < ActiveJob::Base
    def perform(webhook)
      Rails.error.set_context(munster_handler_module_name: webhook.handler_module_name, **Munster.configuration.error_context)

      webhook_details_for_logs = "Munster::ReceivedWebhook#%s (handler: %s)" % [webhook.id, webhook.handler]
      webhook.with_lock do
        unless webhook.received?
          logger.info { "#{webhook_details_for_logs} is being processed in a different job or has been processed already, skipping." }
          return
        end
        webhook.processing!
      end

      if webhook.handler.valid?(webhook.request)
        logger.info { "#{webhook_details_for_logs} starting to process" }
        webhook.handler.process(webhook)
        webhook.processed! if webhook.processing?
        logger.info { "#{webhook_details_for_logs} processed" }
      else
        logger.info { "#{webhook_details_for_logs} did not pass validation by the handler. Marking it `failed_validation`." }
        webhook.failed_validation!
      end
    rescue => e
      webhook.error!
      raise e
    end
  end
end
