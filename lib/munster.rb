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
    attr_accessor :processing_job_class, :active_handlers

    def initialize
      # Remove this configuration option
      @processing_job_class = Munster::ProcessingJob
      @active_handlers = []
    end
  end
end
