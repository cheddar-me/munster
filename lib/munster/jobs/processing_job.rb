# frozen_string_literal: true

require "active_job" if defined?(Rails)

module Munster
  class ProcessingJob < ActiveJob::Base
    def perform(webhook)
      if webhook.handler.valid?(webhook.request)
        # TODO: we are going to add some default state lifecycle managed
        # by the background job later
        webhook.handler.process(webhook)
      else
        Rails.logger.info { "Webhook #{webhook.inspect} did not pass validation and was skipped" }
        webhook.failed_validation!
      end
    end
  end
end
