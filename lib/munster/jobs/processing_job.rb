# frozen_string_literal: true

require "active_job" if defined?(Rails)

module Munster
  class ProcessingJob < ActiveJob::Base
    def perform(webhook)
      webhook.class.transaction do
        webhook.with_lock do
          return unless webhook.received?
          webhook.processing!
        end
      end

      if webhook.handler.valid?(webhook.request)
        webhook.handler.process(webhook)
        webhook.processed! if webhook.processing?
      else
        Rails.logger.info { "#{webhook.class} #{webhook.id} did not pass validation and was skipped" }
        webhook.failed_validation!
      end
    rescue => e
      webhook.error!
      raise e
    end
  end
end
