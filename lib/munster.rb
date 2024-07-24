# frozen_string_literal: true

require_relative "munster/version"
require_relative "munster/engine"
require_relative "munster/jobs/processing_job"
require "active_support/configurable"

module Munster
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield configuration
  end
end

class Munster::Configuration
  include ActiveSupport::Configurable

  config_accessor(:processing_job_class, default: Munster::ProcessingJob)
  config_accessor(:active_handlers, default: {})
  config_accessor(:error_context, default: {})
  config_accessor(:request_body_size_limit, default: 512.kilobytes)
end
