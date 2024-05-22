# frozen_string_literal: true

require_relative "munster/version"
require_relative "munster/engine" if defined?(Rails)

module Munster
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
  end

  class Configuration
    attr_accessor :receive_webhooks_table_name, :processing_job_class, :active_handlers

    def initialize
      @receive_webhooks_table_name = :munster_received_webhooks
      @processing_job_class = Munster::ProcessingJob
      @active_handlers = []
    end
  end
end
