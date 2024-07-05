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

  def self.action_dispatch_request_to_header_hash_and_body(action_dispatch_request)
    # Filter out all Rack-specific headers such as "rack.input" and the like. We are
    # only interested in the headers presented by the webserver
    headers = action_dispatch_request.env.filter_map do |(request_header, header_value)|
      if request_header.is_a?(String) && request_header.upcase == request_header && header_value.is_a?(String)
        [request_header, header_value]
      end
    end.to_h
    [headers, action_dispatch_request.body.read]
  end

  def self.header_hash_and_body_to_action_dispatch_request(header_hash, body_bytes)
    rack_env = header_hash.merge("rack.input" => StringIO.new(body_bytes).binmode)
    ActionDispatch::Request.new(rack_env)
  end
end

class Munster::Configuration
  include ActiveSupport::Configurable

  config_accessor(:processing_job_class) { Munster::ProcessingJob }
  config_accessor(:active_handlers) { [] }
  config_accessor(:error_context) { {} }
end
