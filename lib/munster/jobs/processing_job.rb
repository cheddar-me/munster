# frozen_string_literal: true

require "active_job" if defined?(Rails)

unless defined?(ApplicationJob)
  class ApplicationJob < ActiveJob::Base
  end
end

module Munster
  class ProcessingJob < ApplicationJob
    def perform(webhook)
      # TODO: there should be some sort of locking or concurrency control here, but it's outside of
      # Munsters scope of responsibility. Developer implementing this should decide how this should be handled.
      webhook.handler.process(webhook)
    end
  end
end
