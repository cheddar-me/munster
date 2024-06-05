# frozen_string_literal: true

require_relative "munster/version"
require_relative "munster/engine"
require_relative "munster/jobs/processing_job"
require "active_support/configurable"
require_relative "munster/jobs/processing_job"

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

  config_accessor(:processing_job_class) { Munster::ProcessingJob }
  config_accessor(:active_handlers) { [] }
end
