# frozen_string_literal: true

require_relative "munster/version"
require_relative "munster/engine" if defined?(Rails)

module Munster
  def self.processing_job_class=(job_class)
    @processing_job_class = job_class
  end

  def self.processing_job_class
    @processing_job_class || Munster::ProcessingJob
  end

  def self.receive_webhooks_table_name=(table_name)
    @receive_webhooks_table_name = table_name
  end

  def self.receive_webhooks_table_name
    @receive_webhooks_table_name || "munster_received_webhooks"
  end

  def self.active_handlers=(active_handlers)
    @active_handlers = active_handlers
  end

  def self.active_handlers
    @active_handlers || []
  end
end
