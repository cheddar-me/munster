# frozen_string_literal: true

require "state_machine_enum"

module Munster
  class ReceivedWebhook < ActiveRecord::Base
    self.implicit_order_column = "created_at"
    self.table_name = "received_webhooks"

    include StateMachineEnum

    state_machine_enum :status do |s|
      s.permit_transition(:received, :processing)
      s.permit_transition(:received, :failed_validation)
      s.permit_transition(:processing, :skipped)
      s.permit_transition(:processing, :processed)
      s.permit_transition(:processing, :error)
    end

    def assign_from_request(action_dispatch_request)
      # debugger
      # Filter out all Rack-specific headers such as "rack.input" and the like. We are
      # only interested in the headers presented by the webserver
      headers = action_dispatch_request.env.filter_map do |(request_header, header_value)|
        if request_header.is_a?(String) && request_header.upcase == request_header && header_value.is_a?(String)
          [request_header, header_value]
        end
      end.to_h

      # Path parameters do not get parsed from the request body or the query string, but instead get set by Journey - the Rails
      # router - when the ActionDispatch::Request object gets instantiated. They need to be preserved separately in case the Munster
      # controller gets mounted under a parametrized path - and the path component actually is a parameter that the webhook
      # handler either needs for validation or for processing
      headers["action_dispatch.request.path_parameters"] = action_dispatch_request.env.fetch("action_dispatch.request.path_parameters")

      # If the migration hasn't been applied yet, we can't save the headers.
      if self.class.column_names.include?("request_headers")
        write_attribute("request_headers", headers)
      else
        Rails.logger.warn { "You need to run Munster migrations so that request headers can be persisted with the model. Async validation is not going to work without that column being set." }
      end
      write_attribute("body", action_dispatch_request.body.read.force_encoding(Encoding::BINARY))
    ensure
      action_dispatch_request.body.rewind
    end

    # @return [ActionDispatch::Request]
    def revived_request
      headers = try(:request_headers) || {}
      ActionDispatch::Request.new(headers.merge!("rack.input" => StringIO.new(body)))
    end

    def handler
      handler_module_name.constantize
    end
  end
end
